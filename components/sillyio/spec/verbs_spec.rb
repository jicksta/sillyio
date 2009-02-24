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
      xml_element = xml_node "Play", "http://x.gd/x.wav", "loop" => "-4"
      
      lambda do
        verb = S::Sillyio::Verbs::Play.from_document xml_element
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
    it "should raise an TwiMLFormatException if the value not an integer" do
      xml_element = xml_node "Play", "http://x.gd/x.wav", "loop" => "sexypants"
      
      lambda do
        verb = S::Sillyio::Verbs::Play.from_document xml_element
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
  
  include SillyioTestHelper
  
  describe 'the "action" attribute' do
    it "should convert a relative URL to an absolute URL" do
      relative = "2.xml"
      full = "http://example.com/1.xml"
      full_second = "http://example.com/#{relative}"
      
      xml_element = xml_node "Gather", :action => relative
      
      verb = S::Sillyio::Verbs::Gather.from_document(xml_element, URI.parse(full))
      
      call = new_mock_call
      mock(call).input(is_a(Hash)) { "1111" }
      
      begin
        verb.run call
      rescue S::Sillyio::Redirection => redirection
        redirection.uri.to_s.should eql(full_second)
      else
        fail "No Redirection raised"
      end
      
    end
    it "should default to the current document URL" do
      url = "http://example.com/qaz.xml"
      verb = S::Sillyio::Verbs::Gather.from_document(xml_node("Gather"), URI.parse(url))
      
      call = new_mock_call
      mock(call).input(is_a(Hash)) { "1111" }
      
      begin
        verb.run(call)
      rescue S::Sillyio::Redirection => redirection
        redirection.uri.to_s.should eql(url)
      else
        fail "No Redirection raised"
      end
      
    end
  end
  describe 'the "method" attribute' do
    it 'should allow only "GET" or "POST"' do
      lambda do
        S::Sillyio::Verbs::Gather.from_document(xml_node("Gather", :method => "HEAD"), random_uri)
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
    it "should default to POST" do
      S::Sillyio::Verbs::Gather.from_document(xml_node("Gather"), random_uri).http_method.should eql("post")
    end
  end
  describe 'the "timeout" attribute' do
    it "should default to 5 seconds" do
      S::Sillyio::Verbs::Gather.from_document(xml_node("Gather"), random_uri).timeout.should equal(5)
    end
    it "should raise a TwiMLFormatException if the value is not a positive integer" do
      lambda do
        verb = S::Sillyio::Verbs::Gather.from_document(xml_node("Gather", :timeout => "cough"), random_uri)
      end.should raise_error(S::Sillyio::TwiMLFormatException)
    end
  end
  
  describe 'the "finishOnKey" attribute' do
    it 'should allow the 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, *, "" or # keys' do
      allowed_keys = ("0".."9").to_a + ["*", "#", ""]
      allowed_keys.each do |key|
        xml_element = xml_node("Gather", :finishOnKey => key)
        lambda do
          S::Sillyio::Verbs::Gather.from_document xml_element, random_uri
        end.should_not raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
    it "should not allow any other keys" do
      bad_keys = %w[^ . | < & j a y]
      bad_keys.each do |key|
        xml_element = xml_node("Gather", :finishOnKey => key)
        lambda do
          S::Sillyio::Verbs::Gather.from_document xml_element, random_uri
        end.should raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
    # it "should strip off the terminator" # Handled by Adhearsion
    it "should not allow multiple characters" do
      allowed_keys = (("0".."9").to_a + ["*", "#"]).map { |key| key * 2 }
      allowed_keys.each do |key|
        xml_element = xml_node("Gather", :finishOnKey => key)
        lambda do
          S::Sillyio::Verbs::Gather.from_document xml_element, random_uri
        end.should raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
  end
  
  describe 'the "numDigits" attribute' do
    
    it "should default to 'unlimited'" do
      S::Sillyio::Verbs::Gather.from_document(xml_node("Gather"), random_uri).number_of_digits.should eql("unlimited")
    end
    
    it "should raise a TwiMLFormatException if the integer is less than 1" do # In the future, 0 may become "unlimited"
      ["0", "-1", "-100"].each do |bad_number|
        lambda do
          xml_element = xml_node("Gather", :numDigits => bad_number)
          S::Sillyio::Verbs::Gather.from_document(xml_element, random_uri)
        end.should raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
    
    it "should raise a TwiMLFormatException if the numDigits is not an integer value or 'unlimited'" do
      %w[foo bar qaz 0x100].each do |bad_number|
        lambda do
          xml_element = xml_node("Gather", :numDigits => bad_number)
          S::Sillyio::Verbs::Gather.from_document(xml_element, random_uri)
        end.should raise_error(S::Sillyio::TwiMLFormatException)
      end
    end
  end
  
  it 'should redirect to the script specified in "action" by POSTing or GETing the "Digits" to the URL' do
    application = random_uri
    action = "http://example.com/action.xml"
    digits = "54321"
    # mock(RestClient).post(action, hash_including("Digits" => digits))
    
    xml_element = xml_node "Gather", :action => action, :method => "POST", :numDigits => 5
    verb = S::Sillyio::Verbs::Gather.from_document(xml_element, application)
    
    call = new_mock_call
    mock(call).input(5, is_a(Hash)) { digits }
    
    begin
      app = S::Sillyio.new(call, application.to_s)
      app.send :instance_variable_set, :@parsed_application, [verb]
      app.send :execute_application
    rescue S::Sillyio::Redirection => redirect
      redirect.uri.to_s.should eql(action)
      redirect.http_method.should eql("post")
      redirect.params["Digits"].should == digits
    else
      fail "No Redirection exception raised!"
    end
  end
  
  it 'should redirect to the script specified in "action" when a hangup is encountered during the execution'
  it "should not redirect if a timeout is encountered"
  
  describe "handling nested elements" do
    it "should prepare all nested elements" do
      nested_verb_elements = [
          xml_node("Play", "http://example.com/hello.wav"),
          xml_node("Play", "http://example.com/world.wav")
      ]
      
      gather_and_play = xml_node "Gather", *nested_verb_elements
      
      verb = S::Sillyio::Verbs::Gather.from_document(gather_and_play, random_uri)
      
      verb.nested_verbs.each { |nested_verb| mock(nested_verb).prepare }
      
      verb.prepare
    end
    describe "when a nested element should be loop infinitely" do
      
    end
  end
  
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
  
  include SillyioTestHelper
  
  # I had to clarify this with the 
  it "should default the 'method' to POST when no method is given" do
    xml_element = xml_node "Redirect", "http://example.com"
    S::Sillyio::Verbs::Redirect.from_document(xml_element).http_method.should eql("post")
  end
  
  it "should raise a TwiMLFormatException if the specified 'method' is not GET or POST" do
    xml_element = xml_node "Redirect", "http://example.com", :method => "head"
    
    lambda do
      S::Sillyio::Verbs::Redirect.from_document(xml_element)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
  it "should allow a Symbol for the method" do
    lambda do
      S::Sillyio::Verbs::Redirect.new("http://example.com", :post)
    end.should_not raise_error
  end
  
  it "should raise a TwiMLFormatException if no URL is given" do
    lambda do
      S::Sillyio::Verbs::Redirect.from_document xml_node("Redirect")
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
  it "should raise a Redirection exception containing the new URL, the method, and any new headers when ran" do
    uri = "http://google.com"
    method = "post"
    
    xml_element = xml_node "Redirect", uri, :method => method
    
    begin
      S::Sillyio::Verbs::Redirect.from_document(xml_element).run(new_mock_call)
    rescue S::Sillyio::Redirection => redirect
      redirect.uri.to_s.should eql(uri)
      redirect.http_method.should eql(method)
    else
      fail "No Redirection exception raised!"
    end
  end
  
end

describe "Redirection" do
  
  include SillyioTestHelper
  
  it "should convert a String URL into a URI::HTTP object" do
    S::Sillyio::Redirection.new("http://example.com", :post).uri.should be_kind_of(URI::HTTP)
  end
  
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
    xml_element = xml_node "Pause", :length => "jay"
    
    lambda do
      S::Sillyio::Verbs::Pause.from_document(xml_element)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  it "should raise an TwiMLFormatException if the length attribute is negative" do
    xml_element = xml_node "Pause", :length => "-1"
    
    lambda do
      S::Sillyio::Verbs::Pause.from_document(xml_element)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  it "should default the pause length to 1 second" do
    S::Sillyio::Verbs::Pause.from_document(xml_node("Pause")).sleep_time.should equal(1)
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
    xml_element = xml_node("Hangup", :length => "1")
    
    lambda do
      S::Sillyio::Verbs::Hangup.from_document(xml_element).run(new_mock_call)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
  it "should raise a TwiMLFormatException if element has any children" do
    xml_element = xml_node "Hangup", "blah"
    
    lambda do
      S::Sillyio::Verbs::Hangup.from_document(xml_element).run(new_mock_call)
    end.should raise_error(S::Sillyio::TwiMLFormatException)
  end
  
end
