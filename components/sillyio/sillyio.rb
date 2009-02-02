require 'md5'
require 'fileutils'
require 'base64'

methods_for :rpc do
  def sillyio(application_url)
    Sillyio.new(self, application_url).run
  end
end

class Sillyio
  
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
      "CallGuid"    => "CA#{MD5.md5(call.uniqueid)}",
      "Caller"      => call.callerid,
      "Called"      => call.extension,
      "AccountGuid" => "AC_SILLYIO_#{Process.uid}_#{MD5.md5(`hostname`)}"[0,34]
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
    @application_content = RestClient.post(application, metadata)
  rescue => error
    # TODO
  end
  
  def lexed_application
    @lexed_application = Hpricot.XML @application_content
  end
  
  def parse_application
    @parsed_application = @lexed_application.root.children.map do |element|
      if Verbs.const_defined? element.name.capitalize
        Verbs.const_get(element.name).from_hpricot(element)
      else
        invalid_verb! element
      end
    end
  end
  
  def run_application
    
  end
  
  def metadata
    immediate_call_metadata.merge location_data
  end
  
  def location_data
    {}
  end
  
  def invalid_verb!(element)
    message = <<-MESSAGE
Error parsing document! The following document contains an invalid verb! (#{element.name})

#{@application_content}

Please check the formatting of your
    MESSAGE
    
    ahn_log.sillyio.error message
    
    raise UnrecognizedVerbException, message
    
  end
  
  class TwiMLFormatExpcetion < Exception; end
  class UnrecognizedVerbException < Exception; end
  
  module SillyioSupport
    class << self
      
      ##
      # Returns the HTTP headers as a Hash after doing a HTTP HEAD on a URL. All headers are lowercased.
      #
      def http_head(uri)
        # TODO: support HTTP redirects
        uri = URI.parse uri unless URI.kind_of? URI::HTTP
        response = Net::HTTP.start(uri.host, uri.port) { |http| http.head uri.path }
        if response.code_type == Net::HTTPSuccess
          response.to_hash.inject({}) do |new_response, (header, value)|
            new_response[header] = value.kind_of?(Array) ? value.first : value
            new_response
          end
        else
          nil
        end
      end
      
      def download(source_uri, destination_file)
        Curl::Easy.download @uri, temp_audio_file
      end
    end
  end
  
  module Verbs
    
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
        def from_hpricot(element)
          loop_times = element[:loop]
          raise TwiMLFormatExpcetion, "Play[loop] must be a positive integer" if loop_times !~ /^\d+$/
          loop_times = loop_times.to_i
          
          file_url = element.innerText.strip
          uri = URI.parse uri
          unless uri.kind_of? URI::HTTP
            raise TwiMLFormatExpcetion, "Play URL #{file_url} is not a valid HTTP URL!"
          end
          
        end
      end

      attr_reader :encoded_filename, :audio_directory, :sound_file, :temp_audio_file
      def initialize(uri, loop_times=1)
        raise ArgumentError, "First argument must be a URI object!" unless uri.kind_of? URI::HTTP
        @uri = uri
        
        @encoded_filename = Base64.b64encode(@uri.to_s).chomp
        @audio_directory  = COMPONENTS.sillyio["audio_directory"]
        
        @sound_file      = File.join(audio_directory, "cached", url_encoded_for_filename)
        @temp_audio_file = File.join(audio_directory,    "WIP", url_encoded_for_filename)
      end
      
      def prepare
        return if prepared?

        remote_file_metadata = SillyioSupport.head @uri
        
        content_type = remote_file_metadata["content-type"]
        
        if File.exists?(sound_file) || File.exists?(temp_audio_file)
          # Note: If the temp file exists in WIP, we'll assume another thread is servicing it and it's effectively
          # TODO: Obey caching headers. If remote file has changed, download it again.
        else
          # Download the file.
          SillyioSupport.download @uri, temp_audio_file
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
  end
  
end
