# encoding: UTF-8
module DictClient

  class Client

    def initialize(host = DEFAULT_HOST, port = DEFAULT_PORT)
      @host, @port = host, port
    end

    def connected?
      ! @conn.nil?
    end

    def connect

      @conn = tcp_open @host, @port

      @banner = @conn.readline

      unless DictClient.reply_code(@banner) == RESPONSE_CONNECTED
        raise DictError.new, "Connection refused \"#{@banner}\"."
      end

      # announce ourselves to the server.
      send_command CLIENT_NAME

      unless DictClient.reply_code(reply = @conn.readline()) == RESPONSE_OK
        raise DictError.new, "Client announcement failed \"#{reply}\""
      end

      if block_given?
        yield self
      else
        self
      end

    end

    def disconnect
      if connected?
        send_command 'quit'
        @conn.close
        @conn = nil
      end
    end

    def banner
      check_connection
      @banner
    end

    def databases
      request_response "show db", DictionariesTcpReader.new, Dictionaries
    end

    def strategies
      request_response "show strat", StrategiesTcpReader.new, Strategies
    end

    def server
      request_response "show server", ServerInfoTcpReader.new, ServerInfo
    end

    def help
      request_response "help", ServerHelpTcpReader.new, ServerHelp
    end

    def info database
      request_response %!show info "#{database}"!, DictionaryInfoTcpReader.new, DictionaryInfo
    end

    def match(word, strategy = MATCH_DEFAULT, database = DB_ALL)
      request_response %!match #{database} #{strategy} "#{word}"!, MatchTcpReader.new, WordMatch
    end

    def define(word, database = DB_ALL)
      request_response %!define #{database} "#{word}"!, WordDefinitionsTcpReader.new, WordDefinitions
    end


    private

    def tcp_open host, port
      TCPSocket.open(host, port)
    end

    def request_response(command, reader, response_class)

      send_command command

      if DictClient.reply_code(reply = @conn.readline) == reader.good_response_code
        response_class.new(reader.read_from(@conn))
      elsif reader.bad_response_code && DictClient.reply_code(reply) == reader.bad_response_code
        EmptyResponse.new
      else
        raise DictError.new, reply
      end
    end


    def check_connection
      unless connected?
        raise DictError.new, 'Not connected.'
      end
    end

    def send_command command
      check_connection
      # STDERR.puts command
      @conn.write command + EOL
    end

  end


end

