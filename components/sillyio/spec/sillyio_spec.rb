unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
  elsif File.exists? File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
    # This file may be ran from the within the Adhearsion framework code (before a project has been generated)
    require File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
  else
    path_to_ahn_file = `which ahn`.chomp
    if File.exist?(path_to_ahn_file)
      require File.dirname(path_to_ahn_file) + "/../lib/adhearsion"
    else
      require 'rubygems'
      gem 'adhearsion', '>= 0.8.1'
      require 'adhearsion'
    end
  end
end

# Official specification here: http://www.twilio.com/docs/api_reference/TwiML

require 'adhearsion/component_manager/spec_framework'

S = ComponentTester.new("sillyio", File.dirname(__FILE__) + "/../..")

describe "Instantiating a new Sillyio object" do
  it "should set the call and application_url properties as accessors" do
    p S::Sillyio
    call, url = Object.new, "http://example.com"
    sillyio = S::Sillyio.new(call, url)
    sillyio.call.should equal(sillyio)
  end
  it "should raise an ArgumentError if the URL given is not a valid HTTP or HTTPS URI"
  
end

describe "SillyioHelper" do
  describe "::head" do
    
  end
end


BEGIN {
  module SillyioTestHelper

  end
}