require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RouteRule do
  #fixtures :incoming
  before(:each) do
    @valid_attributes = {
      :did=>"2146935115",
      :url=>"http://www.konectas.com/calls/inbound_start"
    }
    @incoming = RouteRule.new
  end

  it "should create a new instance given valid attributes" do
    @incoming = RouteRule.create!(@valid_attributes)
    #@incoming.attributes = @valid_attributes
    #@incoming.should be_valid
  end

  #it "should be invalid without a did" do
  #  @incoming.attributes = @valid_attributes.except(:did)
  #  @incoming.should_not be_valid
  #  @incomding.did = "2146935115"
  #  @incoming.should be_valid
  #end

  #it "should be invalid without a url" do
  #  @incoming.attributes = @valid_attributes.except(:url)
  #  @incoming.should_not be_valid
  #  @incoming.url = "http://www.konectas.com/calls/inbound_start"
  #  @incoming.should be_valid
  #end

  it "should be invalid without a 10 digit did" do
    @incoming.attributes = @valid_attributes.except(:did)
    @incoming.should_not be_valid
    #number fragment
    @incoming.did = "214693"
    #number fragment with formatting
    @incoming.should_not be_valid
    @incoming.did = "(214) 693-51"
    #full number
    @incoming.should_not be_valid
    @incoming.did = "2146935115"
    @incoming.should be_valid
    #full number with formatting
    @incoming.did = "(214) 693-5115"
    @incoming.should be_valid
  end

  it "should be invalid without a valid url" do
    @incoming.attributes = @valid_attributes
    @incoming.should be_valid
    @incoming.url = ""
    @incoming.should_not be_valid
    @incoming.url = "konectas"
    @incoming.should_not be_valid
    @incoming.url = @valid_attributes[:url]
    @incoming.should be_valid
    @incoming.url = "http://72.249.139.103/calls/inbound_start"
    @incoming.should be_valid
  end
end
