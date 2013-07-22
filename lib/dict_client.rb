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

  # Match strategies.
  MATCH_DEFAULT = '.'
  MATCH_EXACT   = 'exact'
  MATCH_PREFIX  = 'prefix'

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

  def self.reply_code(text, default = nil)

    if text =~ /^\d{3} /
      text.to_i
    elsif default
      default
    else
      raise DictError.new, "Invalid reply from host \"#{text}\"."
    end

  end

end

require 'dict_client/readers.rb'
require 'dict_client/responses.rb'
require 'dict_client/client.rb'
