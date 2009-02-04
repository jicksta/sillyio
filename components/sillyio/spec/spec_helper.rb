unless defined? Adhearsion
  if File.exists? File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
    # If you wish to freeze a copy of Adhearsion to this app, simply place a copy of Adhearsion
    # into a folder named "adhearsion" within this app's main directory.
    require File.dirname(__FILE__) + "/../../../adhearsion/lib/adhearsion.rb"
  elsif File.exists? File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
    # This file may be ran from the within the Adhearsion framework code (before a project has been generated)
    require File.dirname(__FILE__) + "/../../../../../../lib/adhearsion.rb"
  else
    require 'rubygems'
    gem 'adhearsion', '>= 0.8.1'
    require 'adhearsion'
  end
end

require 'adhearsion/component_manager/spec_framework'

S = ComponentTester.new("sillyio", File.dirname(__FILE__) + "/../..")

module SillyioTestHelper

  def initialize_configuration
    mock_component_config_with :sillyio => {"audio_directory" => "site/public/audio"}
    S.initialize!
  end

  def xml_node(name, *args)
    args = args.clone
    options = args.last.kind_of?(Hash) ? args.pop : {}
    returning XML::Node.new(name) do |element|
      options.each_pair { |key,value| element[key.to_s] = value.to_s }
      args.each { |arg| element << arg }
    end
  end

  def play_sequence_with_gather_xml
    <<-XML
    <Response>
      <Play>http://example.com/1.mp3</Play>
      <Play>http://example.com/2.mp3</Play>
      <Play>http://example.com/3.mp3</Play>
      <Gather numDigits="5">
        <Play>http://example.com/4.mp3</Play>
      </Gather>
    </Response>
    XML
  end

  def new_mock_call
    returning Object.new do |call|
      stub(call).uniqueid { Time.now.to_f.to_s }
      stub(call).extension { rand(1000) }
      stub(call).callerid { "Jay Phillips <144422233333>" }
    end
  end
end