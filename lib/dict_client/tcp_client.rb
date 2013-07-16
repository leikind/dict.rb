module DictClient

  class TcpClient

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
        @conn   = nil
        @banner = nil
      end
    end

    def banner
      check_connection
      @banner
    end

    def define(word, database = DB_ALL)
      request_response("define #{database} \"#{word}\"", DictDefinitionList, RESPONSE_DEFINITIONS_FOLLOW, RESPONSE_NO_MATCH)
    end

    def match(word, strategy = MATCH_DEFAULT, database = DB_ALL)
      request_response("match #{database} #{strategy} \"#{word}\"", DictItemListResponse, RESPONSE_MATCHES_FOLLOW, RESPONSE_NO_MATCH)
    end

    def databases
      request_response("show db", DictItemListResponse, RESPONSE_DATABASES_FOLLOW, RESPONSE_NO_DATABASES)
    end

    def strategies
      request_response("show strat", DictItemListResponse, RESPONSE_STRATEGIES_FOLLOW, RESPONSE_NO_STRATEGIES)
    end

    def info database
      request_response("show info \"#{database}\"", SimpleListResponse, RESPONSE_INFO_FOLLOWS)
    end

    def server
      request_response("show server", SimpleListResponse, RESPONSE_SERVER_INFO_FOLLOWS)
    end

    def help
      request_response("help", SimpleListResponse, RESPONSE_HELP_FOLLOWS)
    end

    private

    def tcp_open host, port
      TCPSocket.open(host, port)
    end

    def request_response(command, response_class, good, bad = nil)

      send_command command

      if DictClient.reply_code(reply = @conn.readline) == good
        response_class.new(@conn)
      elsif bad && DictClient.reply_code(reply) == bad
        # "Bad" response, return an empty array
        Array.new
      else
        # Something else
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
      @conn.write command + EOL
    end

  end


end

