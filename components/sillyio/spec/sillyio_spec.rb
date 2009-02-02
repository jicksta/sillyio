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
  
  it "should raise an ArgumentError if the URL given is not a valid HTTP or HTTPS URI" do
    lambda do
      S::Sillyio.new(new_mock_call, "ajsndfjnasd")
    end.should raise_error(ArgumentError)
  end
  
  describe "The TwiML metadata" do
    
    it "should create the metadata with the CallGuid, Caller, Called, and AccountGuid keys" do
      metadata = S::Sillyio.new(new_mock_call, "http://example.com").immediate_call_metadata
      %w[CallGuid Caller Called AccountGuid].each do |key|
        metadata.has_key?(key).should equal(true)
      end
    end    
  end
  
end

describe "Executing a TwiML resource" do
  
  include SillyioTestHelper
  
  describe "Fetching the TwiML resource" do
    it "should post the location headers with RestClient" do
      
      location_data_header_keys = ["CallerCity", "CallerState", "CallerZip", "CallerCountry", "CalledCity",
          "CalledState", "CalledZip", "CalledCountry"]
      
      location_data_headers = location_data_header_keys.inject({}) do |hash, key|
        hash[key] = key.reverse
        hash
      end
      
      sillyio = S::Sillyio.new(new_mock_call, 'http://example.com')
      mock(sillyio).location_data { location_data_headers }
      
      mock(RestClient).post is_a(URI::HTTP), hash_including(location_data_headers)
      
      sillyio.send :fetch_application
    end
  end
  
  describe "Lexing the TwiML resource" do
    it "should raise a TwiMLFormatException if the document has no Response element" do
      xml = "<Respon><Hangup/></Respon>"
      sillyio = S::Sillyio.new(new_mock_call, 'http://example.com')
      
      sillyio.send(:instance_variable_set, :@application_content, xml)
      
      lambda do
        sillyio.send :lex_application
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
  end
  
  describe "Parsing the TwiML resource" do
    it "should convert all elements into their appropriate verbs using Verb::from_hpricot" do
      xml = play_sequence_with_gather_xml
      sillyio = S::Sillyio.new(new_mock_call, "http://example.com")
      sillyio.send(:instance_variable_set, :@application_content, xml)
      sillyio.send :lex_application
      sillyio.send :parse_application
      
      
      parsed_application = sillyio.send(:instance_variable_get, :@parsed_application)
      
      parsed_application.zip(
        [S::Sillyio::Verbs::Play,
         S::Sillyio::Verbs::Play, S::Sillyio::Verbs::Play,
          S::Sillyio::Verbs::Gather]).each do |(verb_object, verb_class)|
            
        verb_object.should be_instance_of(verb_class)
      end
    end
  end
  
  describe "Running the TwiML resource" do
    it "should prepare() all of the verbs" do
      
    end
    it "should call parse() run(call) on all of the verbs" do
      call = new_mock_call
      sillyio = S::Sillyio.new(call, "http://example.com")
      sillyio.send(:instance_variable_set, :@application_content, play_sequence_with_gather_xml)
      sillyio.send :lex_application
      sillyio.send :parse_application
      sillyio.send(:instance_variable_get, :@parsed_application).each do |verb|
        mock(verb).parse
        mock(verb).run call
      end
      sillyio.run
    end
  end
end

describe "SillyioHelper" do
  describe "::head" do
    
  end
end


BEGIN {
  module SillyioTestHelper

    def play_sequence_with_gather_xml
      <<-XML
      <Response>
        <Play>http://example.com/1.mp3</Play>
        <Play>http://example.com/2.mp3</Play>
        <Play>http://example.com/3.mp3</Play>
        <Gather numDigits="5">
          <Play>http://example.com/4.mp3</Play>
        </Gather>
      </Response>
      XML
    end

    def new_mock_call
      returning Object.new do |call|
        stub(call).uniqueid { Time.now.to_f.to_s }
        stub(call).extension { rand(1000) }
        stub(call).callerid { "Jay Phillips <144422233333>" }
      end
    end
  end
}