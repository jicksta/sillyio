# This is a Sinatra app.

require 'rubygems'
require 'sinatra'

def get_and_post(*args, &block)
  get(*args, &block)
  post(*args, &block)
end

##
# This will <Play> back the digits that have been submitted to it via GET and POST
#
get_and_post "/play-gathered-digits" do
  content_type 'application/xml', :charset => 'utf-8'
  
  digits = params["Digits"]
  
  if digits
    separated_digits = digits.split("")
    play_commands = separated_digits.map { |digit| "<Play>http://sandbox.adhearsion.com/sounds/digits/#{digit}.gsm</Play>" }
    <<-XML
      <?xml version="1.0" encoding="UTF-8" ?>
      <Response>
        #{play_commands.join("\n")}
      </Response>
    XML
  else
    <<-XML
    <?xml version="1.0" encoding="UTF-8" ?>
    <Response>
      <Play>http://sandbox.adhearsion.com/sounds/sorry-youre-having-problems.gsm</Play>
    </Response>
    XML
  end

end