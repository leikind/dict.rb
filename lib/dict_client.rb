# encoding: UTF-8
require 'socket'

module DictClient

  DEFAULT_HOST = 'dict.mova.org'

  DEFAULT_PORT = 2628

  EOL = "\r\n"

  # End of data marker
  EOD = '.' + EOL

  # The special database names.
  DB_FIRST = '!'
  DB_ALL   = '*'

  # The guaranteed match strategies.
  MATCH_DEFAULT = '.'
  MATCH_EXACT   = 'exact'
  MATCH_PREFIX  = 'prefix'

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

  CLIENT_NAME = 'client github.com/leikind/dict_client'

  class DictError < RuntimeError
  end


  # Get the reply code of the passed text.
  def self.reply_code(text, default = nil)

    if text =~ /^\d{3} /
      text.to_i
    elsif default
      default
    else
      raise DictError.new, "Invalid reply from host \"#{text}\"."
    end

  end

  class BasicResponse

    def initialize
      @list = []
    end

    def push item
      @list.push item
    end

    def each
      @list.each{|i| yield i}
    end

    def empty?
      @list.empty?
    end
  end


  class DictDefinition < BasicResponse

    attr_reader :database, :name, :word

    def initialize(details, conn)

      super()

      # Split the details out.
      details     = /^\d{3} "(.*?)"\s+(\S+)\s+"(.*)"/.match(details)

      @word       = details[1]
      @database   = details[2]
      @name       = details[3]

      # Read in the definition.
      while (reply = conn.readline()) != EOD
        push reply.chop
      end

    end

    # Return an array of words you should also see in regard to this definition.
    def see_also
      join('').scan /\{(.*?)\}/
    end

  end

  class DictItem

    attr_reader :name, :description

    def initialize text
      match        = /^(\S+)\s+"(.*)"/.match(text)
      @name        = match[1]
      @description = match[2]
    end

  end


  class DictDefinitionList < BasicResponse

    def initialize conn

      super()

      # While there's a definition to be had...
      while DictClient.reply_code(reply = conn.readline()) == RESPONSE_DEFINITION_FOLLOWS
        push DictDefinition.new(reply, conn)
      end

    end

  end


  class SimpleListResponse < BasicResponse

    def initialize conn

      super()

      while DictClient.reply_code(reply = conn.readline(), 0) != RESPONSE_OK
        push reply unless reply == EOD
      end
    end

  end

  class DictItemListResponse < SimpleListResponse

    def push text
      super DictItem.new(text)
    end

  end


end

require 'dict_client/tcp_client.rb'
