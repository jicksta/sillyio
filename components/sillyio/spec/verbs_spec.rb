unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
  elsif File.exists? File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
    # This file may be ran from the within the Adhearsion framework code (before a project has been generated)
    require File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
  else
    path_to_ahn_file = `which ahn`.chomp
    p ENV["PATH"], path_to_ahn_file
    if File.exist?(path_to_ahn_file)
      require File.dirname(path_to_ahn_file) + "/../lib/adhearsion"
    else
      require 'rubygems'
      gem 'adhearsion', '>= 0.8.1'
      require 'adhearsion'
    end
  end
end

# Official specification here: http://www.twilio.com/docs/api_reference/TwiML

require 'adhearsion/component_manager/spec_framework'

RESTFUL_RPC = ComponentTester.new("sillyio", File.dirname(__FILE__) + "/../..")

describe "Say" do
  
  describe '"voice" attribute' do
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
  
  it "should download the file to a base64 encoded form of the URL"
  
end

describe "Gather" do
  describe 'the "action" attribute' do
    it "should convert a relative URL to an absolute URL"
    it "should default to the current document URL"
  end
  describe 'the "method" attribute' do
    it 'should allow only "GET" or "POST"'
    it "should default to POST"
    it "should raise a TwiMLFormatException if the value is anything else"
  end
  describe 'the "timeout" attribute' do
    it "should default to 5 seconds"
    it "should raise a TwiMLFormatException if the value is not a positive integer"
  end
  
  describe 'the "finishOnKey" attribute' do
    it 'should allow the 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, *, "" or # keys'
    it "should not allow any other keys"
    it "should strip off the terminator"
    it "should not allow multiple characters"
  end
  
  describe 'the "numDigits" attribute' do
    it "should default to unlimited"
    it "should raise a TwiMLFormatException if the integer is less than 0"
    it "should riase a TwiMLFormatException if the numDigits is not an integer value"
  end
  
  it 'should redirect to the script specified in "action" by POSTing or GETing the "Digits" to the URL'
  it 'should redirect to the script specified in "action" when a hangup is encountered during the execution'
  it "should not redirect if a timeout is encountered"
  
end

describe "Record" do
  
  describe "The file submission when the recording has completed" do
    it "should send a properly formatted RecordingUrl"
    it "should send the duration of the recorded audio file"
    it "should send the digit used to end the recording"
    it "should send an empty string for Digits if the timeout was reached"
  end
  
  describe 'the "action" attribute' do
    it "should default to the current document URL"
  end
  
  describe 'the "method" attribute' do
    it "should allow only GET or POST"
    it "should default to POST"
  end
  
  describe 'the "timeout" attribute' do
    it "should raise a TwiMLFormatException if not a positive integer"
    it "should default to 5 seconds"
  end
  
  describe 'the "finishOnKey" attribute' do
    it 'should allow the 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, *, "" or # keys'
    it "should not allow any other keys"
    
    it "should allow multiple characters"
  end
  
  describe 'the "maxLength" attribute' do
    it "should default to 1 hour (3600 seconds)"
    it "should raise a TwiMLFormatException if the value is not a positive integer"
  end
  
  it "should keep track of the digit used to end the call and submit it when redirecting to the action as 'Digits'"
  
end

describe "Dial" do
  
  it "should strip any hyphens in the number"
  
  it "should not try to submit the outcome of the dial if no action is provided"
  
  it "should convert Asterisk DIALSTATUS responses to the appropriate TwiML"
  
  describe "Nested Number element(s)" do
    it "should convert "
  end
end

describe "Redirect" do
  it "should forward the session state"
  # it "should default the 'method' to POST" # Docs not clear.
  it "should raise a TwiMLFormatException if no 'method' attribute is given"
  it "should raise a Redirection exception containing the new URL"
end

describe "Redirection" do
  it "should require the URL"
  it "should optionally allow the storing of HTTP headers"
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