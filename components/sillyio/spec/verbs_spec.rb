require File.dirname(__FILE__) + "/spec_helper"

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
  
  include SillyioTestHelper
  
  before :each do
    initialize_configuration
  end
  
  describe "The audio file Content-Type check" do
    
    %w[audio/mpeg audio/wav audio/wave audio/x-wav audio/aiff audio/x-aifc
        audio/x-aiff audio/x-gsm audio/gsm audio/ulaw].each do |content_type|
      it "should allow the #{content_type} content type" do
        stub_actual_fetching content_type
        verb = S::Sillyio::Verbs::Play.new(URI.parse("http://example.com"))
        lambda do
          verb.prepare
        end.should_not raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
    it "should not allow other Content-Types" do
      stub_actual_fetching "x-blahh"
      verb = S::Sillyio::Verbs::Play.new(URI.parse("http://example.com"))
      lambda do
        verb.prepare
      end.should raise_error(S::Sillyio::TwiMLDownloadException)
    end
  end  
  
  describe 'The "loop" attribute' do
    it "should invoke loop() if the value is zero (for unlimited)" do
      sound_file = "http://example.com/example.wav"
      verb = S::Sillyio::Verbs::Play.new(URI.parse(sound_file), 0)
      mock(verb).loop { throw :looped! }
      
      call = new_mock_call
      
      stub_actual_fetching
      
      verb.prepare
      lambda { verb.run(call) }.should throw_symbol(:looped!)
    end
    it "should invoke play a given number of times if number greater than 1 is given" do
      times = 12
      sound_file = "http://example.com/example.wav"
      
      verb = S::Sillyio::Verbs::Play.new(URI.parse(sound_file), times)
      
      call = new_mock_call
      mock(call).play(is_a(String)).times(times)
      
      stub_actual_fetching
      
      verb.prepare
      verb.run(call)
    end
    it "should raise an TwiMLFormatException if the value is negative" do
      xml_element = XML::Node.new("Play")
      xml_element["loop"] = "-4"
      xml_element << "http://x.gd/x.wav"
      lambda do
        verb = S::Sillyio::Verbs::Play.from_xml_element xml_element
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
    it "should raise an TwiMLFormatException if the value not an integer" do
      xml_element = XML::Node.new("Play")
      xml_element["loop"] = "sexypants"
      xml_element << "http://x.gd/x.wav"
      lambda do
        verb = S::Sillyio::Verbs::Play.from_xml_element xml_element
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
  end
  
  it "should download the file to a base64 encoded form of the URL" do
    url = "http://sillyio.com/testing/sound_files/hello-world.gsm"
    encoded_filename = "aHR0cDovL3NpbGx5aW8uY29tL3Rlc3Rpbmcvc291bmRfZmlsZXMvaGVsbG8td29ybGQuZ3Nt"
    
    play = S::Sillyio::Verbs::Play.new(URI.parse(url))
    play.encoded_filename.should eql(encoded_filename)
    
    filename = "aHR0cDovL3NpbGx5aW8uY29tL3Rlc3Rpbmcvc291bmRfZmlsZXMvaGVsbG8td29ybGQuZ3Nt.gsm"
    mock(S::Sillyio::SillyioSupport).http_head(is_a(URI::HTTP)) { {"content-type" => "audio/x-gsm"} }
    mock(S::Sillyio::SillyioSupport).download(url, /#{filename}$/)
    mock(FileUtils).mv(is_a(String), is_a(String))
    play.prepare
    play.sound_file.ends_with?("/#{filename}").should equal(true)
  end
  
  def stub_actual_fetching(content_type="audio/x-gsm")
    stub(S::Sillyio::SillyioSupport).http_head(is_a(URI::HTTP)) { {"content-type" => content_type} }
    stub(S::Sillyio::SillyioSupport).download(is_a(String), is_a(String))
    stub(FileUtils).mv(is_a(String), is_a(String))
  end
  
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
  
  include SillyioTestHelper
  
  before :each do
    initialize_configuration
  end
  
  it "should sleep for the number of seconds specified in the 'length' property" do
    length = 3
    verb = S::Sillyio::Verbs::Pause.new(length)
    mock(verb).sleep length
    verb.run(new_mock_call)
  end
  it "should raise an TwiMLFormatException if the length attribute is not an integer" do
    xml_element = XML::Node.new("Pause")
    xml_element["length"] = "jay"
    lambda do
      S::Sillyio::Verbs::Pause.from_xml_element(xml_element)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  it "should raise an TwiMLFormatException if the length attribute is negative" do
    xml_element = XML::Node.new("Pause")
    xml_element["length"] = "-1"
    lambda do
      S::Sillyio::Verbs::Pause.from_xml_element(xml_element)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
end

describe "Hangup" do
  
  include SillyioTestHelper
  
  before :each do
    initialize_configuration
  end
  
  it "should execute the Adhearsion hangup() method" do
    call = new_mock_call
    mock(call).hangup
    S::Sillyio::Verbs::Hangup.new.run(call)
  end
  
  it "should raise a TwiMLFormatException if element has any attributes" do
    xml_element = XML::Node.new("Hangup")
    xml_element["length"] = "1"
    lambda do
      S::Sillyio::Verbs::Hangup.from_xml_element(xml_element).run(new_mock_call)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
  it "should raise a TwiMLFormatException if element has any children" do
    xml_element = XML::Node.new("Hangup")
    xml_element << "blah"
    lambda do
      S::Sillyio::Verbs::Hangup.from_xml_element(xml_element).run(new_mock_call)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
end
