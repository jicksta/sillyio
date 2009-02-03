require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RouteRule do
  #fixtures :incoming
  before(:each) do
    @valid_attributes = {
      :did=>"2146935115",
      :url=>"http://www.konectas.com/calls/inbound_start"
    }
    @incoming = RouteRule.new(@valid_attributes)
  end

  it "should create a new instance given valid attributes" do
    #@incoming = Incoming.create!(@valid_attributes)
    @incoming.should be_valid
  end

  it "should be invalid without a did" do
    @incoming.attributes = @valid_attributes
    @incoming.did = nil
    @incoming.should_not be_valid
  end

  it "should be invalid without a url" do
    @incoming.attributes = @valid_attributes
    @incoming.url = nil
    @incoming.should_not be_valid
  end

  it "should be invalid without a 10 digit did" do

  end

  it "should be invalid without a valid url" do
    
  end
end
