# Official specification here: http://www.twilio.com/docs/api_reference/TwiML
require File.dirname(__FILE__) + "/spec_helper"

describe "Instantiating a new Sillyio object" do
  
  include SillyioTestHelper
  
  before :each do
    initialize_configuration
  end
  
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
  
  before :each do
    initialize_configuration
  end
  
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
      
      mock(RestClient).post 'http://example.com', hash_including(location_data_headers)
      
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
    
    it "should raise a TwiMLSyntaxException if the document is invalid XML" do
      sillyio = S::Sillyio.new(new_mock_call, 'http://example.com')
      sillyio.send(:instance_variable_set, :@application_content, "<<ASNDASND")
      lambda do
        sillyio.send :lex_application
      end.should raise_error(S::Sillyio::TwiMLSyntaxException)
    end
  end
  
  describe "Parsing the TwiML resource" do
    it "should convert all elements into their appropriate verbs" do
      xml = play_sequence_with_gather_xml
      sillyio = S::Sillyio.new(new_mock_call, "http://example.com")
      sillyio.send(:instance_variable_set, :@application_content, xml)
      sillyio.send :lex_application
      sillyio.send :parse_application
      
      parsed_application = sillyio.send(:instance_variable_get, :@parsed_application)
      
      parsed_application.zip(
        [S::Sillyio::Verbs::Play,
         S::Sillyio::Verbs::Play,
         S::Sillyio::Verbs::Play,
         S::Sillyio::Verbs::Gather]
      ).each do |(verb_object, verb_class)|
        verb_object.should be_instance_of(verb_class)
      end
    end
  end
  
  describe "Running the TwiML resource" do
    
    it "should call prepare() and run(call) on all of the verbs" do
      call = new_mock_call
      
      sillyio = S::Sillyio.new(call, "http://example.com")
      sillyio.send(:instance_variable_set, :@application_content, play_sequence_with_gather_xml)
      
      sillyio.send :lex_application
      sillyio.send :parse_application
      sillyio.send(:instance_variable_get, :@parsed_application).each do |verb|
        mock(verb).prepare
        mock(verb).run call
      end
      sillyio.send :execute_application
    end
  end
  
  describe "when redirecting" do
    
    it "should change the HTTP method if appropriate" do
      first_url = "http://example.com/1.xml"
      second_url = "http://example.com/2.xml"
      
      mock(RestClient).post(first_url, is_a(Hash)) { <<-XML }
        <Response>
          <Redirect method="get">#{second_url}</Redirect>
        </Response>
      XML
      mock(RestClient).get(second_url, is_a(Hash)) { <<-XML }
        <Response></Response>
      XML
      
      S::Sillyio.new(new_mock_call, first_url).run
    end
    
  end
  
end

describe "SillyioSupport" do
  describe "::head" do
    
  end
end


