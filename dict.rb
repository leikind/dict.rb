#!/usr/bin/env ruby
### dict.rb --- RFC 2229 client for ruby.
## Copyright 2002,2003 by Dave Pearson <davep@davep.org>
## $Revision: 1.9 $
##
## dict.rb is free software distributed under the terms of the GNU General
## Public Licence, version 2. For details see the file COPYING.

### Commentary:
##
## The following code provides a set of RFC 2229 client classes for ruby.
## See <URL:http://www.dict.org/> for more details about dictd.

### TODO:
##
## o Add support for AUTH.

# We need sockets.
require "socket"


class DictError < RuntimeError
end

module Dict

  DEFAULT_HOST = "localhost"

  DEFAULT_PORT = 2628

  EOL = "\r\n"

  # End of data marker
  EOD = "." + EOL

  # The special database names.
  DB_FIRST = "!"
  DB_ALL   = "*"

  # The guaranteed match strategies.
  MATCH_DEFAULT = "."
  MATCH_EXACT   = "exact"
  MATCH_PREFIX  = "prefix"

  # The various response numbers.
  RESPONSE_DATABASES_FOLLOW    = 110
  RESPONSE_STRATEGIES_FOLLOW   = 111
  RESPONSE_INFO_FOLLOWS        = 112
  RESPONSE_HELP_FOLLOWS        = 113
  RESPONSE_SERVER_INFO_FOLLOWS = 114
  RESPONSE_DEFINITIONS_FOLLOW  = 150
  RESPONSE_DEFINITION_FOLLOWS  = 151
  RESPONSE_MATCHES_FOLLOW      = 152
  RESPONSE_CONNECTED           = 220
  RESPONSE_OK                  = 250
  RESPONSE_NO_MATCH            = 552
  RESPONSE_NO_DATABASES        = 554
  RESPONSE_NO_STRATEGIES       = 555

  # Get the reply code of the passed text.
  def reply_code(text, default = nil)

    if text =~ /^\d{3} /
      text.to_i
    elsif default
      default
    else
      raise DictError.new(), "Invalid reply from host \"#{text}\"."
    end

  end

  private :reply_code

end

class DictBase
  include Dict
end

class DictDefinition < Array

  include Dict

  attr_reader :database, :name, :word

  def initialize(details, conn)

    super()

    # Split the details out.
    details     = /^\d{3} "(.*?)"\s+(\S+)\s+"(.*)"/.match( details )

    @word       = details[1]
    @database   = details[2]
    @name       = details[3]

    # Read in the definition.
    while ( reply = conn.readline() ) != EOD
      push reply.chop
    end

  end


  # Return an array of words you should also see in regard to this definition.
  def see_also
    join('').scan( /\{(.*?)\}/ )
  end

end


class DictDefinitionList < Array

  include Dict

  def initialize(conn)

    super()

    # While there's a definition to be had...
    while reply_code( reply = conn.readline() ) == RESPONSE_DEFINITION_FOLLOWS
      push DictDefinition.new(reply, conn)
    end

  end

end


class DictArray < Array

  include Dict

  def initialize( conn )

    super()

    # While there's a match to be had...
    while reply_code( reply = conn.readline(), 0 ) != RESPONSE_OK
      # ...add it to the list.
      push reply if reply != EOD
    end

  end

end

# Class for holding a dictionary item in a dictionary array.
class DictArrayItem

  attr_reader :name, :description

  def initialize( text )
    match        = /^(\S+)\s+"(.*)"/.match( text )
    @name        = match[1]
    @description = match[2]
  end

end

class DictItemArray < DictArray

  def push(text)
    super DictArrayItem.new(text)
  end

end

class DictClient < DictBase

  attr_reader :host, :port

  def initialize(host = DEFAULT_HOST, port = DEFAULT_PORT)
    @host   = host
    @port   = port
    @conn   = nil
    @banner = nil
  end

  def connected?
    @conn != nil
  end

  def check_connection
    unless connected?
      raise DictError.new(), 'Not connected.'
    end
  end

  private :check_connection

  def send_command(text)
    check_connection
    @conn.write(text + EOL)
  end

  private :send_command

  def connect

    if connected?
      raise DictError.new(), 'Attempt to connect a conencted client.'
    else

      @conn = TCPSocket.open(host, port)

      @banner = @conn.readline

      # Valid return value?
      unless reply_code(@banner) == RESPONSE_CONNECTED
        raise DictError.new, "Connection refused \"#{@banner}\"."
      end

      # Now we announce ourselves to the server.
      send_command("client org.davep.dict.rb $Revision: 1.9 $ <URL:http://www.davep.org/misc/dict.rb>")

      unless reply_code( reply = @conn.readline() ) == RESPONSE_OK
        raise DictError.new(), "Client announcement failed \"#{reply}\""
      end

      # If we were passed a block, yield to it
      yield self if block_given?

    end

  end

  def disconnect

    if connected?
      send_command 'quit'
      @conn.close
      @conn   = nil
      @banner = nil
    else
      raise DictError.new(), "Attempt to disconnect a disconnected client."
    end

  end

  def banner
    check_connection
    @banner
  end

  def form_command(command, array_class, good, bad = nil)

    send_command command

    # Worked?
    if reply_code(reply = @conn.readline) == good
      array_class.new(@conn)
    elsif bad & reply_code(reply) == bad
      # "Bad" response, return an empty array
      Array.new
    else
      # Something else
      raise DictError.new(), reply
    end

  end

  private :form_command

  def define(word, database = DB_ALL)
    form_command("define #{database} \"#{word}\"", DictDefinitionList, RESPONSE_DEFINITIONS_FOLLOW, RESPONSE_NO_MATCH)
  end

  def match(word, strategy = MATCH_DEFAULT, database = DB_ALL)
    form_command("match #{database} #{strategy} \"#{word}\"", DictItemArray, RESPONSE_MATCHES_FOLLOW, RESPONSE_NO_MATCH)
  end

  def databases
    form_command("show db", DictItemArray, RESPONSE_DATABASES_FOLLOW, RESPONSE_NO_DATABASES)
  end

  def strategies
    form_command("show strat", DictItemArray, RESPONSE_STRATEGIES_FOLLOW, RESPONSE_NO_STRATEGIES)
  end

  def info(database)
    form_command("show info \"#{database}\"", DictArray, RESPONSE_INFO_FOLLOWS)
  end

  def server
    form_command("show server", DictArray, RESPONSE_SERVER_INFO_FOLLOWS)
  end

  def help
    form_command("help", DictArray, RESPONSE_HELP_FOLLOWS)
  end

end

############################################################################
# Provide a dict command.
if $0 == __FILE__

  # We're going to use long options.
  require "getoptlong"

  # Command result
  result = 1

  # Default parameters.
  $params = {
    :host       => ENV[ "DICT_HOST" ]  || Dict::DEFAULT_HOST,
    :port       => ENV[ "DICT_PORT" ]  || Dict::DEFAULT_PORT,
    :database   => ENV[ "DICT_DB" ]    || Dict::DB_ALL,
    :strategy   => ENV[ "DICT_STRAT" ] || Dict::MATCH_DEFAULT,
    :match      => false,
    :dbs        => false,
    :strats     => false,
    :serverhelp => false,
    :info       => nil,
    :serverinfo => false,
    :help       => false,
    :licence    => false
  }

  # Print the help screen.
  def printHelp
    print "dict.rb v#{/(\d+\.\d+)/.match( '$Revision: 1.9 $' )[ 1 ]}
Copyright 2002,2003 by Dave Pearson <davep@davep.org>
http://www.davep.org/

Supported command line options:

  -h --host <host>         Specify the host to be contacted
                           (default is \"#{Dict::DEFAULT_HOST}\").
  -p --port <port>         Specify the port to be connected
                           (default is #{Dict::DEFAULT_PORT}).
  -d --database <db>       Specity the database to be searched
                           (default is \"#{Dict::DB_ALL}\").
  -m --match               Perform a match instead of a define.
  -s --strategy <strat>    Specity the strategy to use for the match/define
                           (default is \"#{Dict::MATCH_DEFAULT}\").
  -D --dbs                 List databases available on the server.
  -S --strats              List stratagies available on the server.
  -H --serverhelp          Display the server's help.
  -i --info <db>           Display information about a database.
  -I --serverinfo          Display information about the server.
     --help                Display this help.
  -L --licence             Display the licence for this program.

Supported environment variables:

  DICT_HOST                Specify the host to be contacted.
  DICT_PORT                Specify the port to be connected.
  DICT_DB                  Specify the database to be searched.
  DICT_STRAT               Specify the strategy to use for the match/define.

"
  end

  # Print the licence.
  def printLicence
   print "dict.rb - RFC 2229 client for ruby.
Copyright (C) 2002,2003 Dave Pearson <davep@davep.org>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 675 Mass
Ave, Cambridge, MA 02139, USA.

"
  end

  # Get the arguments from the command line.
  begin
    GetoptLong.new().set_options(
                                 [ "--host",       "-h", GetoptLong::REQUIRED_ARGUMENT ],
                                 [ "--port",       "-p", GetoptLong::REQUIRED_ARGUMENT ],
                                 [ "--database",   "-d", GetoptLong::REQUIRED_ARGUMENT ],
                                 [ "--match",      "-m", GetoptLong::NO_ARGUMENT       ],
                                 [ "--strategy",   "-s", GetoptLong::REQUIRED_ARGUMENT ],
                                 [ "--dbs",        "-D", GetoptLong::NO_ARGUMENT       ],
                                 [ "--strats",     "-S", GetoptLong::NO_ARGUMENT       ],
                                 [ "--serverhelp", "-H", GetoptLong::NO_ARGUMENT       ],
                                 [ "--info",       "-i", GetoptLong::REQUIRED_ARGUMENT ],
                                 [ "--serverinfo", "-I", GetoptLong::NO_ARGUMENT       ],
                                 [ "--help",             GetoptLong::NO_ARGUMENT       ],
                                 [ "--licence",    "-L", GetoptLong::NO_ARGUMENT       ]
                                 ).each {|name, value| $params[ name.gsub( /^--/, "" ).intern ] = value }
  rescue GetoptLong::Error
    printHelp()
    exit 1
  end

  # Method for printing titles.
  def title( text, char )
    print( ( char * 76 ) + "\n#{text}\n" + ( char * 76 ) + "\n"  )
  end

  # Method for printing a list.
  def print_list( name, list )
    title("#{name} available on #{$params[ :host ]}:#{$params[ :port ]}", "=")
    list.each {|item| print item.class == DictArrayItem ? "#{item.name} - #{item.description}\n" : item }
    print "\n"
  end

  # The need for help overrides everything else
  if $params[:help]
    printHelp
    result = 0
  elsif $params[:licence]
    # As does the need for the legal mumbojumbo
    printLicence
    result = 0
  else

    begin

      DictClient.new( $params[ :host ], $params[ :port ] ).connect() do |dc|

        # User wants to see a list of databases?
        print_list( "Databases", dc.databases ) if $params[:dbs]

        # User wants to see a list of strategies?
        print_list( "Strategies", dc.strategies ) if $params[:strats]

        # User wants to see the server help?
        print_list( "Server help", dc.help ) if $params[:serverhelp]

        # User wants to see help on a database?
        print_list( "Info for #{$params[ :info ]}", dc.info( $params[:info] ) ) if $params[:info]

        # User wants to see server information?
        print_list( "Server information", dc.server ) if $params[:serverinfo]

        # Look up any words left on the command line.
        ARGV.each do |word|

          title( "Word: #{word}", "=" )

          # Did the user require a match?
          if $params[:match]

            # Yes, display matches.
            if ( matches = dc.match( word, $params[:strategy], $params[:database] ) ).empty?
              print "No matches found\n"
            else
              matches.each {|wm| print "Database: \"#{wm.name}\" Match: \"#{wm.description}\"\n" }
            end

          else

            # No, display definitions.
            if (defs = dc.define( word, $params[:database])).empty?
              print "No definitions found\n"
            else
              defs.each do |wd|
                title("From: #{wd.database} - #{wd.name}", "-")
                wd.each {|line| print line + "\n" }
              end
            end

          end

        end

        dc.disconnect

      end

      # If we made it this far everything should have worked.
      result = 0

    rescue SocketError => e
      print "Error connecting to server: #{e}\n"
    rescue DictError => e
      print "Server error: #{e}\n"
    rescue Errno::ECONNREFUSED => e
      print "Error connecting to server: #{e}\n"
    end

  end

  exit result

end
