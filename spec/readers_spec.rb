# encoding: UTF-8
require 'spec_helper.rb'

describe DictClient::DictionariesTcpReader do

  let!(:socket){MockedDictdServerSocket.new}

  before{socket.write 'show db'}


  it 'reads lines correctly' do
    lines = subject.read_from socket
    lines.size.should == 8

    lines[0].should == "110 94 databases present\n"
    lines[-1].should == %!mech_mime "mech"\n!
  end
end

describe DictClient::WordDefinitionsTcpReader do

  let!(:socket){MockedDictdServerSocket.new}

  before{socket.write 'define * "apple"'}


  it 'reads lines correctly' do
    lines = subject.read_from socket
    lines.size.should == 19

    lines[0].should == "150 6 definitions retrieved\r\n"
    lines[1].should == "151 \"apple\" slovnyk_en-uk \"slovnyk_en-uk\"\r\n"
  end
end