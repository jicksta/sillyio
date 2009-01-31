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
    gem 'adhearsion', '>= 0.7.999'
    require 'adhearsion'
  end
end

require 'adhearsion/component_manager/spec_framework'

RESTFUL_RPC = ComponentTester.new("restful_rpc", File.dirname(__FILE__) + "/../..")

describe "Say" do
  describe '"voice" attribute'
    it "should allow only 'man' and 'woman'"
    it 'should default to "man"'
  end
  describe '"language" attribute' do
    it "should allow only 'en', 'es', 'fr', and 'de'"
    it "should default to 'en'"
  end
  
  describe 'The "loop" attribute' do
    it "should invoke loop() if the value is zero"
    it "should invoke Fixnum#times if the value is greater than zero"
    it "should raise an TwiMLFormatException if the value is negative"
    it "should raise an TwiMLFormatException if the value not an integer"
  end
  
end

describe "Play" do
  describe "The audio file Content-Type check" do
    %w[audio/mpeg audio/wav audio/wave audio/x-wav audio/aiff audio/x-aifc
        audio/x-aiff audio/x-gsm audio/gsm audio/ulaw].each do |content_type|
      it "should allow #{content_type}" do
        mock(something.headers)["Content-Type"].returns content_type
      end
    end
    it "should not allow other Content-Types"
  end  
  
  describe 'The "loop" attribute' do
    it "should invoke loop() if the value is zero"
    it "should invoke Fixnum#times if the value is greater than zero"
    it "should raise an TwiMLFormatException if the value is negative"
    it "should raise an TwiMLFormatException if the value not an integer"
  end
  
end


describe "Dial" do
  it "should strip any hyphens in the number"
end
describe "Redirect" do
  it "should forward the session state"
  it "should instantiate a new Sillyio object with the Redirect element's text"
end

describe "Gather" do
  
end

describe "Pause" do
  it "should sleep for the number of seconds specified in the 'length' property"
  it "should raise an TwiMLFormatException if the length attribute is not an integer"
  it "should raise an TwiMLFormatException if the length attribute is negative"
end

describe "Hangup" do
  it "should execute the Adhearsion hangup() method"
  it "should raise a TwiMLFormatException if element has any innerText or attributes"
end