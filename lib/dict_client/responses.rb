# encoding: UTF-8
module DictClient

  class EmptyResponse
    def to_s
      'none'
    end
  end

  class SimpleResponse

    def initialize lines
      lines.each do |line|
        process_line line
      end
    end

    def to_s
      @response
    end

    private

    def process_line line
      @response ||= ''

      @response << line
    end
  end

  ServerInfo      = SimpleResponse
  ServerHelp      = SimpleResponse
  DictionaryInfo  = SimpleResponse

  module Formattable
    def longest list
      list.max{|a,b| a.length <=> b.length }.length
    end

    def print_formatted list, max_key, max_value
      list.to_a.map do |k, v|
        sprintf "%#{max_key}s  %-#{max_value}s", k, v
      end.join("\n")
    end
  end

  class KeyValueResponse < SimpleResponse

    include Formattable

    def to_h
      @table
    end

    def to_s
      max_value = longest @table.values
      max_key =   longest @table.keys

      print_formatted @table, max_key, max_value

    end

    private

    def process_line line
      @table ||= {}

      if line =~ /^([^\s]+)\s+"(.+?)"/
        @table[$1] = $2
      end
    end

  end


  Dictionaries = KeyValueResponse

  Strategies   = KeyValueResponse

  class WordMatch < SimpleResponse

    include Formattable

    attr_reader :matches

    def to_s
      max_key   = longest @matches.map{|tuple| tuple[0] }
      max_value = longest @matches.map{|tuple| tuple[1] }

      print_formatted @matches, max_key, max_value
    end

    def count
      @matches.size
    end

    private

    def process_line line
      @matches ||= []

      if line =~ /^([^\s]+)\s+"([^"]+)"/
        @matches << [$1, $2]
      end
    end

  end

  class WordDefinitions < SimpleResponse

    attr_reader :definitions

    def initialize lines
      @definitions = []
      super(lines)
    end

    class WordDefinition < Struct.new(:word, :dictionary_name, :dictionary_description, :definition)

      BAR = ('-' * 76) + "\n"

      def to_s(n = nil)
        (n.nil? ? '' : "#{n}) ") +
        "#{dictionary_name} (#{dictionary_description}): #{word}\n" +
        BAR + definition + BAR
      end
    end


    def to_s
      @definitions.each_with_index.to_a.map{|definition, idx| definition.to_s(idx+1)}.join
    end

    def count
      @definitions.size
    end

    private

    def process_line line
      if line =~ /^#{RESPONSE_DEFINITION_FOLLOWS}\s+"([^\s+]+)"\s+([^\s+]+)\s+"(.+?)"/
        word, dictionary_name, dictionary_description = $1, $2, $3

        @current_definition = WordDefinition.new(word, dictionary_name, dictionary_description, '')
        @definitions << @current_definition

      else
        if @current_definition
          @current_definition.definition << line
        end
      end

    end

  end

end