require 'md5'
require 'fileutils'
require 'base64'

begin
  require 'rest_client'
rescue LoadError
  abort "Sillyio depends on the RestClient gem. Please install it by doing 'sudo gem install rest-client'"
end

begin
  require 'xml'
rescue LoadError
  abort <<-MESSAGE
Sillyio depends on the libxml-ruby gem. Please install it by doing 'sudo gem install libxml-ruby'.

Note: This gem does not really work on Windows.

On OSX, you may need to do 'sudo port install rb-libxml2'.
  
On Ubuntu, do "sudo apt-get install libxml-ruby libxml2-dev" and then "sudo gem install libxml-ruby".
  MESSAGE
end

begin
  require 'curl'
rescue LoadError
  abort "Sillyio depends on the curb gem. Please install it by doing 'sudo gem install curb'. On Ubuntu you'll need to do 'apt-get install libcurl4-openssl-dev'. Note: You'll need the Ruby development headers installed for the compile to work."
end


methods_for :dialplan do
  
  def sillyio(application_url)
    Sillyio.new(self, application_url).run
  rescue Sillyio::TwiMLFormatException => format_error
    ahn_log.sillyio.error format_error
  rescue Sillyio::TwiMLDownloadException => download_error
    ahn_log.sillyio.error "DOWNLOAD ERROR! #{download_error.message}"
  end
  
end

class Sillyio
  
  class << self
    def account_guid
      @@account_guid ||= "AC_SILLYIO_#{Process.uid}_#{MD5.md5(`hostname`)}"[0,34]
    end
  end
  
  attr_reader :application, :call, :immediate_call_metadata
  def initialize(call, application)
    @call = call
    @application = URI.parse application
    @http_method = "post"
    
    # Note: URI::HTTPS is a subclass of URI::HTTP, therefore also valid.
    unless @application.kind_of? URI::HTTP
      raise ArgumentError, @application.inspect + " must be a valid HTTP or HTTPS URL!"
    end
    
    # This is the metadata the TwiML spec has us POST to the URL.
    @immediate_call_metadata = {
      "CallGuid"    => "CA#{MD5.md5(call.uniqueid.to_s)}",
      "Caller"      => call.callerid,
      "Called"      => call.extension,
      "AccountGuid" => self.class.account_guid
    }
    
  end
  
  def run
    fetch_application
    lex_application
    parse_application
    execute_application
  rescue Redirection => redirection
    @application = redirection.uri
    @http_method = redirection.http_method
    @additional_headers = redirection.params
    retry
  end
  
  protected
  
  def fetch_application
    @application_content = RestClient.send(@http_method, application.to_s, metadata)
  rescue => error
    ahn_log.sillyio.error error
    raise TwiMLDownloadException, "Could not fetch #@application"
  end
  
  def lex_application
    @lexed_application = begin
      doc = XML::Parser.string(@application_content).parse
      
      # Make sure the document has a <Response> root
      raise TwiMLFormatException, "No <Response> element!" unless doc.root.name == "Response"
      
      # Make sure we recognize all the Verbs
      invalid_verbs = doc.find("/Response//*").select { |element| not Verbs.const_defined? element.name }
      raise UnrecognizedVerbException.new(*invalid_verbs.uniq) if invalid_verbs.any?
      
      doc.find("/Response/*").to_a # Ignores text elements
    end
  rescue LibXML::XML::Error => parse_error
    raise TwiMLSyntaxException, parse_error.message
  end
  
  def parse_application
    # Check all Verb names
    @parsed_application = @lexed_application.map do |element|
      Verbs.const_get(element.name).from_document(element, @application)
    end
  end
  
  def execute_application
    @parsed_application.each do |verb|
      # TODO: Prepare verbs in parallel
      verb.prepare if verb.respond_to? :prepare
      verb.run @call
    end
  end
  
  def metadata
    immediate_call_metadata.merge(location_data).merge(additional_headers)
  end
  
  def additional_headers
    @additional_headers || {}
  end
  
  def location_data
    {}
  end
  
  class Redirection < Exception
    
    attr_reader :uri, :params, :http_method
    def initialize(uri, http_method, params={})
      @http_method = http_method.to_s.downcase
      raise ArgumentError, "Unrecognized method #{method}" unless %w[post get].include? @http_method
      @uri    = uri.kind_of?(String) ? URI.parse(uri) : uri
      @params = params
      super()
    end
    
  end
  
  class TwiMLDownloadException < Exception; end
  
  class TwiMLFormatException < Exception; end
  class TwiMLSyntaxException < TwiMLFormatException; end
  
  class UnrecognizedVerbException < TwiMLFormatException
    def initialize(*verb_names)
      super "Unrecognized verbs: " + verb_names.to_sentence
    end
  end
  
  module SillyioSupport
    class << self
      
      ##
      # Returns the HTTP headers as a Hash after doing a HTTP HEAD on a URL. All headers are lowercased.
      #
      def http_head(uri)
        # TODO: Use recursion to support HTTP redirects
        uri = URI.parse uri unless uri.kind_of? URI::HTTP
        response = Net::HTTP.start(uri.host, uri.port) { |http| http.head uri.path }
        if response.kind_of? Net::HTTPOK
          response.to_hash.inject({}) do |new_response, (header, value)|
            new_response[header] = value.kind_of?(Array) ? value.first : value
            new_response
          end
        else
          nil
        end
      end
      
      def download(source_uri, destination_file)
        Curl::Easy.download source_uri, destination_file
      end
    end
  end
  
  module Verbs
    
    RECOGNIZED_SOUND_FORMATS = %w[audio/mpeg audio/wav audio/wave audio/x-wav audio/aiff audio/x-aifc
        audio/x-aiff audio/x-gsm audio/gsm audio/ulaw]
    
    VERB_DEFAULTS = {
      "Say" => {
        :voice    => "man",
        :language => "en",
        :loop     => "1"
      },
      "Play" => {
        :loop => "1"
      },
      "Gather" => {
        # :action => DYNAMIC! MUST BE SET IN METHOD,
        :method      => "POST",
        :timeout     => "5",
        :finishOnKey => '#',
        :numDigits   => "unlimited"
      },
      "Record" => {
        # :action    => DYNAMIC! MUST BE SET IN METHOD,
        :method      => "POST",
        :timeout     => "5",
        :finishOnKey => "1234567890*#",
        :maxlength   => 1.hour 
      },
      "Dial" => {
        # :action     => DYNAMIC! MUST BE SET IN METHOD,
        :method       => "POST",
        :timeout      => "30",
        :hangupOnStar => "false",
        # :callerId   => DYNAMIC! MUST BE SET IN METHOD,
        :timeLimit    => "value"
      },
      "Redirect" => { :method => "POST" },
      "Pause"    => { :length =>    "1" },
      "Hangup"   => {}
    }
    
    class AbstractVerb
      class << self
        def attributes_from_xml_element(element)
          VERB_DEFAULTS[name[/::([^:]+)$/,1]].merge((element.attributes.to_h || {}).symbolize_keys)
        end
      end
    end
    
    # http://www.twilio.com/docs/api_reference/TwiML/play
    class Play < AbstractVerb

      class << self
        def from_document(element, uri=nil)
          attributes = attributes_from_xml_element element
          
          loop_times = extract_loop_attribute attributes
          
          # Pull out the text within the element
          file_url = element.content.strip
          
          # Make sure a URL was given
          raise TwiMLFormatException, "No file URL given!" if file_url.empty?
          
          file_uri = URI.parse file_url
          
          # Must be a HTTP or HTTPS URI.
          raise TwiMLFormatException, "Play URL #{file_url} is not a valid HTTP URL!" unless file_uri.kind_of? URI::HTTP
          
          new(file_uri, loop_times)
        end
        
        protected

        def extract_loop_attribute(attributes)
          loop_times = attributes[:loop]
          raise TwiMLFormatException, "Play[loop] must be a positive integer" if loop_times !~ /^\d+$/
          loop_times = loop_times.to_i
        end

      end

      attr_reader :encoded_filename, :audio_directory, :sound_file, :playable_sound_file_name, :temp_sound_file, :loop_times
      def initialize(uri, loop_times=1)
        raise ArgumentError, "First argument must be a URI object!" unless uri.kind_of? URI::HTTP
        @uri = uri
        @loop_times = loop_times
        
        @encoded_filename = Base64.encode64(@uri.to_s).gsub("\n", "")
        @audio_directory  = COMPONENTS.sillyio["audio_directory"]
      end
      
      def prepare
        remote_file_metadata = SillyioSupport.http_head @uri
        
        raise TwiMLDownloadException, "Could not do a HEAD on #{@uri}" unless remote_file_metadata
        
        content_type = remote_file_metadata["content-type"]
        
        unless RECOGNIZED_SOUND_FORMATS.include? content_type
          raise TwiMLDownloadException, "Audio file #{@uri} does not have a valid Content-Type! (#{content_type})" 
        end
        
        file_extension = content_type[/^audio\/(x-)?(.+)$/, 2]
        
        # Cannot give extension to Asterisk
        @playable_sound_file_name = File.expand_path "#{@audio_directory}/cached/#{@encoded_filename}"
        
        @sound_file        = File.expand_path "#{@audio_directory}/cached/#{@encoded_filename}.#{file_extension}"
        @temp_sound_file   = File.expand_path "#{@audio_directory}/WIP/#{@encoded_filename}.#{file_extension}"
        
        if File.exists?(sound_file) || File.exists?(temp_sound_file)
          # Note: If the temp file exists in WIP, we'll assume another thread is servicing it and it's effectively
          # TODO: Obey caching headers. If remote file has changed, download it again.
        else
          # Download the file.
          SillyioSupport.download @uri.to_s, temp_sound_file
          FileUtils.mv temp_sound_file, sound_file
        end
        
        @prepared = true
      end
      
      def infinite?
        loop_times.zero?
      end
      
      def run(call)
        if infinite?
          loop { call.play @playable_sound_file_name }
        else
          loop_times.times { call.play @playable_sound_file_name }
        end
      end
      
    end
  
    # http://www.twilio.com/docs/api_reference/TwiML/gather
    class Gather < AbstractVerb
      
      class << self
        def from_document(element, uri)
          attributes = attributes_from_xml_element element
          
          raise ArgumentError, "URI must be a URI class" unless uri.kind_of? URI::HTTP
          
          # Checking the 'action' attribute
          action = attributes[:action] || uri.to_s
          if action !~ %r"https?://"
            # Relative paths are added to the application URI
            action = uri.merge URI.parse(action)
          end
          
          # Checking the "method" attribute
          http_method = attributes[:method].downcase
          raise TwiMLFormatException, "Gather 'method' must be GET or HEAD" unless %w[get post].include? http_method
          
          # Checking the timeout attribute
          timeout = attributes[:timeout]
          raise TwiMLFormatException, "Gather 'timeout' is not a positive integer!" unless timeout =~ /^[1-9]\d*$/
          timeout = timeout.to_i
          
          # Checking the "finishOnKey" attribute
          terminating_key = attributes[:finishOnKey]
          unless((("0".."9").to_a + ["*", "#", ""]).include?(terminating_key))
            raise TwiMLFormatException, "Invalid finishOnKey attribute (#{terminating_key}) for <Gather>" 
          end
          
          # Checking the "numDigits" attribtue
          number_of_digits = attributes[:numDigits]
          unless number_of_digits =~ /^[1-9]\d*$/ || number_of_digits == "unlimited"
            raise TwiMLFormatException, "Gather 'numDigits' is not a positive integer!" 
          end
          number_of_digits = number_of_digits == "unlimited" ? number_of_digits : number_of_digits.to_i
          
          nested_verbs = element.find("Play|Say").to_a do |child|
            Verbs.const_get(child.name).from_document(child, uri)
          end.compact
          
          new(action, http_method, timeout, terminating_key, number_of_digits, *nested_verbs)
        end
      end
      
      attr_reader :action, :http_method, :timeout, :terminating_key, :number_of_digits, :nested_verbs, :result
      def initialize(action, http_method, timeout, terminating_key, number_of_digits, *nested_verbs)
        @action, @http_method, @timeout, @terminating_key, @number_of_digits = action, http_method, timeout, terminating_key, number_of_digits
        @nested_verbs = nested_verbs.flatten
      end
      
      def prepare
        # Prepare all verbs concurrently
        # nested_verbs.map do |verb|
        #   Thread.new { verb.prepare }
        # end.map(&:join)
        p nested_verbs
        nested_verbs.each(&:prepare)
      end
      
      def run(call)
        if nested_verbs.find(&:infinite?)
          preliminary_sound_files, unplayable_sound_files = [], nil
          infinitely_played_file  = nil
          
          nested_verbs.each_with_index do |verb, index|
            if verb.infinite?
              infinitely_played_file = verb
              unplayable_sound_files = nested_verbs[index+1..-1]
            else
              preliminary_sound_files << verb
            end
          end
          
          if unplayable_sound_files.any?
            ahn_log.sillyio.warn "<Gather> contains unplayable sound files: #{unplayable_sound_files.inspect}"
          end
          
          run_with_files(call, *sound_file_names_from_verbs(preliminary_sound_files))
          
          # If a Redirection has not been raised yet, we'll continue.
          
          options = {
            :play            => infinitely_played_file.playable_sound_file_name,
            :timeout         => @timeout,
            :terminating_key => @terminating_key
          }
          
          @result = if @number_of_digits == "unlimited"
            call.input options
          else
            call.input @number_of_digits, options
          end
          
          loop do
            @result = if @number_of_digits == "unlimited"
              call.input options
            else
              call.input @number_of_digits, options
            end
            
            redirect_with_digits @result if @result
          end
          
        else
          run_with_files(call, *sound_file_names_from_verbs(nested_verbs))
        end
        
      end
      
      protected
      
      def sound_file_names_from_verbs(*verbs)
        verbs.flatten.inject([]) do |expanded_verbs, verb|
          loop_times = verb["loop"] || 1
          expanded_verbs + ([verb.playable_sound_file_name] * loop_times.to_i)
        end
      end
      
      def run_with_files(call, *files)
        options = {
          :play            => files,
          :timeout         => @timeout,
          :terminating_key => @terminating_key
        }
      
        @result = if @number_of_digits == "unlimited"
          call.input options
        else
          call.input @number_of_digits, options
        end
        redirect_with_digits @result if @result
      end

      def redirect_with_digits(digits)
        raise Redirection.new(@action, @http_method, {"Digits" => digits})
      end

      
    end
  
  
  
    # http://www.twilio.com/docs/api_reference/TwiML/pause
    class Pause < AbstractVerb
      class << self
        def from_document(element, uri=nil)
          attributes = attributes_from_xml_element element
          length = attributes[:length]
          raise TwiMLFormatException, 'Invalid <Pause> "length" attribute!' if length !~ /^[1-9]\d*$/
          new length.to_i
        end
      end
      
      attr_reader :sleep_time
      def initialize(length)
        @sleep_time = length
      end
      
      def run(call)
        sleep sleep_time
      end
      
    end
    
    # http://www.twilio.com/docs/api_reference/TwiML/pause
    class Hangup < AbstractVerb
      class << self
        def from_document(element, uri=nil)
          raise TwiMLFormatException, "<Hangup> requires no attributes!" unless element.attributes.length.zero?
          raise TwiMLFormatException, "<Hangup> can have no children!" unless element.empty?
          new
        end
      end
      
      def run(call)
        call.hangup
      end
      
    end
  
    class Redirect < AbstractVerb
      
      class << self
        def from_document(element, uri=nil)
          attributes = attributes_from_xml_element element
          method = attributes[:method].downcase
          raise TwiMLFormatException, "Redirect method must be GET or HEAD" unless %w[get post].include? method
          
          raise TwiMLFormatException, "No URL given to <Redirect>!" unless element.first?
          uri = element.content
          
          new(uri, method)
        end
      end
      
      attr_reader :redirection, :http_method
      def initialize(uri, method)
        @http_method = method.to_s.downcase
        raise ArgumentError, "Unrecognized method #{method}" unless %w[post get].include? @http_method
        @uri = uri
        
        @redirection = Redirection.new(uri, @http_method)
      end
      
      def run(call)
        raise @redirection
      end
      
    end
  
  end
  
end
