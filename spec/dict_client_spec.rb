require 'spec_helper.rb'

describe DictClient do
  context '#reply_code' do

    it "catches invalid response codes" do
      DictClient.reply_code('hello', :error).should == :error
    end

  end
end