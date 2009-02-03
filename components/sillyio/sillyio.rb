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
    run_application
  end
  
  protected
  
  def fetch_application
    @application_content ||= RestClient.post(application.to_s, metadata)
  rescue => error
    ahn_log.sillyio.error error
    raise TwiMLDownloadException, "Could not fetch #@application"
  end
  
  def lex_application
    @lexed_application ||= begin
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
    @parsed_application ||= @lexed_application.map do |element|
      Verbs.const_get(element.name).from_xml_element element
    end
  end
  
  def run_application
    @parsed_application.each do |verb|
      # TODO: Prepare verbs in parallel
      verb.prepare
      verb.run @call
    end
  end
  
  def metadata
    @metadata ||= immediate_call_metadata.merge(location_data)
  end
  
  def location_data
    {}
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
        :numDigits   => "0"
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
    
    # http://www.twilio.com/docs/api_reference/TwiML/play
    class Play

      class << self
        def from_xml_element(element)
          attributes = VERB_DEFAULTS["Play"].merge element.attributes.to_h.symbolize_keys
          loop_times = attributes[:loop]
          raise TwiMLFormatException, "Play[loop] must be a positive integer" if loop_times !~ /^\d+$/
          loop_times = loop_times.to_i
          
          file_url = element.content.strip
          uri = URI.parse file_url
          unless uri.kind_of? URI::HTTP
            raise TwiMLFormatException, "Play URL #{file_url} is not a valid HTTP URL!"
          end
          new(uri, loop_times)
        end
      end

      attr_reader :encoded_filename, :audio_directory, :sound_file, :temp_audio_file
      def initialize(uri, loop_times=1)
        raise ArgumentError, "First argument must be a URI object!" unless uri.kind_of? URI::HTTP
        @uri = uri
        
        @encoded_filename = Base64.encode64(@uri.to_s).gsub("\n", "")
        @audio_directory  = COMPONENTS.sillyio["audio_directory"]
      end
      
      def prepare
        return if prepared?

        remote_file_metadata = SillyioSupport.http_head @uri
        
        raise TwiMLDownloadException, "Could not do a HEAD on #{@uri}" unless remote_file_metadata
        
        content_type = remote_file_metadata["content-type"]
        
        unless RECOGNIZED_SOUND_FORMATS.include? content_type
          raise TwiMLDownloadException, "Audio file #{@uri} does not have a valid Content-Type! (#{content_type})" 
        end
        
        file_extension = content_type[/^audio\/(.+)$/, 1]
        
        @sound_file      = File.expand_path "#{@audio_directory}/cached/#{@encoded_filename}.#{file_extension}"
        @temp_audio_file = File.expand_path "#{@audio_directory}/WIP/#{@encoded_filename}.#{file_extension}"
        
        if File.exists?(sound_file) || File.exists?(temp_audio_file)
          # Note: If the temp file exists in WIP, we'll assume another thread is servicing it and it's effectively
          # TODO: Obey caching headers. If remote file has changed, download it again.
        else
          # Download the file.
          SillyioSupport.download @uri.to_s, temp_audio_file
          FileUtils.mv temp_audio_file, sound_file
        end
        
        @prepared = true
      end
      
      def prepared?
        @prepared
      end
      
      def run(call)
        prepare unless prepared?
        call.play sound_file
      end
      
    end
  
    class Gather
      
      class << self
        def from_xml_element(element)
          new
        end
      end
      
      def initialize
      end
      
      def prepare
      end
      
      def run
      end
      
    end
  
  end
  
end
