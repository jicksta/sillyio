unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
  elsif File.exists? File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
    # This file may be ran from the within the Adhearsion framework code (before a project has been generated)
    require File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
  else
    require 'rubygems'
    gem 'adhearsion', '>= 0.8.1'
    require 'adhearsion'
  end
end

# Official specification here: http://www.twilio.com/docs/api_reference/TwiML

require 'adhearsion/component_manager/spec_framework'

S = ComponentTester.new("sillyio", File.dirname(__FILE__) + "/../..")
  
describe "Instantiating a new Sillyio object" do
  
  include SillyioTestHelper
  
  it "should make an accessor of the call object" do
    call = new_mock_call
    sillyio = S::Sillyio.new(call, "http://example.com")
    sillyio.call.should equal(call)
    
  end
  
  it "should convert the URL to a URI object" do
    url = "http://example.com/#{rand}"
    sillyio = S::Sillyio.new(new_mock_call, url)
    
    sillyio.application.should be_kind_of(URI)
    sillyio.application.to_s.should eql(url)
    
  end
  
  
  it "should raise an ArgumentError if the URL given is not a valid HTTP or HTTPS URI"
  
end

describe "SillyioHelper" do
  describe "::head" do
    
  end
end


BEGIN {
  module SillyioTestHelper

    def new_mock_call
      returning Object.new do |call|
        stub(call).uniqueid { Time.now.to_f.to_s }
        stub(call).extension { rand(1000) }
        stub(call).callerid { "Jay Phillips <144422233333>" }
      end
    end
  end
}