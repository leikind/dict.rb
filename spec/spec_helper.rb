# encoding: UTF-8

require 'dict_client'

class MockedDictdServerSocket

  attr_reader :incoming_commands

  SHOW_DB_RESPONSE = [
    %!110 94 databases present\n!,
    %!abr1w "Словарь синонимов Н.Абрамова"\n!,
    %!muiswerk "Dutch monolingual dictionary"\n!,
    %!magus "Новый Большой англо-русский словарь"\n!,
    %!he-ru "A collection of Hebrew-Russian dictionaries"\n!,
    %!ru-he "A collection of Russian-Hebrew dictionaries"\n!,
    %!mech_nomime "mech"\n!,
    %!mech_mime "mech"\n!,
    %!.\r\n!,
    %!250 ok\n!
  ]

  APPLE_DEFINITIONS = [
    %!150 6 definitions retrieved\r\n!,
    %!151 "apple" slovnyk_en-uk "slovnyk_en-uk"\r\n!,
    %!APPLE\r\n!,
      %!"ЯБЛУКО"\r\n!,
    %!.\r\n!,
    %!151 "apple" slovnyk_en-ru "slovnyk_en-ru"\r\n!,
    %!APPLE\r\n!,
      %!"ЯБЛОНЕВЫЙ"\r\n!,
    %!.\r\n!,
    %!151 "apple" slovnyk_en-pl "slovnyk_en-pl"\r\n!,
    %!APPLE\r\n!,
      %!"JABŁKO"\r\n!,
    %!.\r\n!,
    %!151 "apple" slovnyk_en-be "slovnyk_en-be"\r\n!,
    %!APPLE\r\n!,
      %!"ЯБЛЫК"\r\n!,
    %!.\r\n!,
    %!151 "apple" slovnyk_en-be "slovnyk_en-be"\r\n!,
    %!APPLE\r\n!,
      %!"ЯБЛЫКА"\r\n!,
    %!.\r\n!,
    %!151 "apple" sinyagin_general_er "sinyagin_general_er"\r\n!,
    %!apple\r\n!,
            %!яблоко\r\n!,
    %!.\r\n!,
    %!250 ok [d/m/c = 17/0/396; 0.000r 0.000u 0.000s]\r\n!
  ]


  def initialize
    @incoming_commands = []
    @response = "220 \r\n"
  end

  def readline
    if @response_queue && ! @response_queue.empty?
      @response_queue.shift
    else
      @response
    end
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
    when /^show db/
      @response_queue = SHOW_DB_RESPONSE.clone
    when /^define \* "apple"/

      @response_queue = APPLE_DEFINITIONS.clone
    end

  end
end
