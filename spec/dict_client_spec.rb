require 'spec_helper.rb'

describe DictClient do
  context '#reply_code' do

    it "catches invalid response codes" do
      DictClient.reply_code('hello', :error).should == :error
    end

    it "catches invalid response codes throwing exceptions" do
      ->{DictClient.reply_code('hello')}.should raise_error(DictClient::DictError)
    end


    it "returns valid response codes" do
      DictClient.reply_code("250 \r\n", :error).should == 250
    end


  end
end