# This is a Sinatra app.

require 'rubygems'
require 'sinatra'

def get_and_post(*args, &block)
  get(*args, &block)
  post(*args, &block)
end

get_and_post "/play-digits" do
  content_type 'application/xml', :charset => 'utf-8'
  <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Gather action="/play-gathered-digits" method="POST" finishOnKey="#" numDigits="5" timeout="5"/>
  <Play>http://sandbox.adhearsion.com/sounds/tt-monkeys.gsm</Play>
</Response>
  XML

end

##
# This will <Play> back the digits that have been submitted to it via GET and POST
#
get_and_post "/play-gathered-digits" do
  content_type 'application/xml', :charset => 'utf-8'
  digits = request.POST["Digits"]
  
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
