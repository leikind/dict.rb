# encoding: UTF-8
require 'spec_helper.rb'

describe DictClient::Client do

  let!(:dictd){}

  subject do
    DictClient::Client.new.tap do |client|
      def client.tcp_open(h,p)
        MockedDictdServerSocket.new.tap{|m| @mock = m}
      end

      def client.mock
        @mock
      end
    end
  end

  it 'connects' do
    subject.connect.should == subject
  end


  it 'client command has been sent' do
    subject.connect
    subject.mock.incoming_commands[0].should match(/^client /)
  end

  context 'disconnected' do

    before do
      subject.connect
      subject.disconnect
    end

    its(:connected?){ should be_false }

    it 'client command has been sent' do
      subject.mock.incoming_commands[1].should match(/^quit\r\n/)
    end

  end


  context 'inside a session' do
    before do
      subject.connect
    end

    after do
      subject.disconnect
    end


    its(:connected?){ should be_true }

  end

end