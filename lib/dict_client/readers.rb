# encoding: UTF-8
module DictClient

  class SimpleTcpReader

    def read_from socket

      [].tap do |lines|
        while DictClient.reply_code(reply = socket.readline(), 0) != RESPONSE_OK
          lines.push reply.force_encoding('UTF-8') unless reply == EOD
        end
      end

    end

    def good_response_code
      nil
    end

    def bad_response_code
      nil
    end
  end

  class  DictionariesTcpReader < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_DATABASES_FOLLOW
    end

    def bad_response_code
      ::DictClient::RESPONSE_NO_DATABASES
    end
  end

  class StrategiesTcpReader  < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_STRATEGIES_FOLLOW
    end

    def bad_response_code
      ::DictClient::RESPONSE_NO_STRATEGIES
    end
  end

  class ServerHelpTcpReader  < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_HELP_FOLLOWS
    end
  end

  class ServerInfoTcpReader  < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_SERVER_INFO_FOLLOWS
    end
  end

  class DictionaryInfoTcpReader  < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_INFO_FOLLOWS
    end
  end

  class MatchTcpReader  < SimpleTcpReader
    def good_response_code
      ::DictClient::RESPONSE_MATCHES_FOLLOW
    end

    def bad_response_code
      ::DictClient::RESPONSE_NO_MATCH
    end

  end

  class WordDefinitionsTcpReader  < SimpleTcpReader

    def good_response_code
      ::DictClient::RESPONSE_DEFINITIONS_FOLLOW
    end

    def bad_response_code
      ::DictClient::RESPONSE_NO_MATCH
    end

  end
end
