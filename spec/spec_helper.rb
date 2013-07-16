require 'dict_client'

DictClient::TcpClient

class MockedDictdServerSocket

  attr_reader :incoming_commands

  def initialize
    @incoming_commands = []
    @response = "220 \r\n"
  end

  def readline
    @response
  end

  def close
    true
  end

  def write command
    # puts "--- received command #{command}"
    @incoming_commands << command
    case command
    when /^client /
      @response = "250 \r\n"
    end
  end

end
