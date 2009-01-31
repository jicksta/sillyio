methods_for :rpc do
  def sillyio(url)
    Sillyio.new(self, application_url).run!
  end
end


class Sillyio
  
  attr_reader :application_url, :call, :immediate_call_metadata
  def initialize(call, application_url)
    @call = call
    @application_url = application_url
    
    # This is the metadata the TwiML spec has us POST to the URL.
    @immediate_call_metadata = {
      "CallGuid"    => "CA#{MD5.md5(uniqueid)}"
      "Caller"      => call.callerid,
      "Called"      => call.extension,
      "AccountGuid" => "AC_SILLYIO_#{Process.uid}_#{MD5.md5(`hostname`)}"[0,34]
    }
  end
  
  def run!
    fetch_application
    lex_application
    parse_application
    run_application
  end
  
  protected
  
  def fetch_application
    @application_content = RestClient.post(application_url, metadata)
  rescue => error
    # TODO
  end
  
  def lexed_application
    @lexed_application = Hpricot.XML @application_content
  end
  
  def parse_application
    @parsed_application = @lexed_application.root.children.map do |element|
      if Verbs.const_defined? element.name
        Verbs.const_get(element.name).new(element)
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
  
  class UnrecognizedVerbException < Exception; end
  
  module Verbs
    class Play
      
      ALLOWED_CONTENT_TYPES = %w[mpeg wav wave x-wav aiff x-aifc x-aiff x-gsm gsm ulaw ].map { |format| "audio/#{format}" }
      
      def initialize(element)
        
      end
      
    end
    
  end
end