require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CallerId do
  before(:each) do
    @valid_attributes = {
      :did => "2146935115",
      :description => "(214) 693-5115"
    }
    @caller_id = CallerId.new
  end

  it "should create a new instance given valid attributes" do
    @caller_id = CallerId.create!(@valid_attributes)
  end
  
  it "should be invalid without a valid 10 digit did" do
    
    @caller_id.attributes = @valid_attributes.except(:did)
    @caller_id.should_not be_valid
    #number fragment
    @caller_id.did = "214693"
    #number fragment with formatting
    @caller_id.should_not be_valid
    @caller_id.did = "(214) 693-51"
    #full number
    @caller_id.should_not be_valid
    @caller_id.did = "2146935115"
    @caller_id.should be_valid
    #full number with formatting
    @caller_id.did = "(214) 693-5115"
    @caller_id.should be_valid

  end
  
  it "should be invalid without a valid description" do
    @caller_id.attributes = @valid_attributes
    @caller_id.should be_valid
    @caller_id.description = nil
    @caller_id.should_not be_valid
  end
  
  it "should automatically generate a formatted description from the did but should not overwrite a non-default description" do
    @caller_id.attributes = @valid_attributes.except(:description)
    @caller_id.should be_valid
    @caller_id.description.to_s.should eql("(#{@caller_id.did[0..2]}) #{@caller_id.did[3..5]}-#{@caller_id.did[6..9]}")
    @caller_id.description = "New description"
    @caller_id.should be_valid
    @caller_id.did = "4097531266"
    @caller_id.description.to_s.should eql("New description")
    @caller_id.description = "(409) 753-1266"
    @caller_id.should be_valid
    @caller_id.did = @valid_attributes[:did]
    @caller_id.description.to_s.should eql("(214) 693-5115")
    @caller_id.should be_valid
  end
end
