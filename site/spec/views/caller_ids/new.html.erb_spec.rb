require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/caller_ids/new.html.erb" do
  include CallerIdsHelper
  
  before(:each) do
    assigns[:caller_id] = stub_model(CallerId,
      :new_record? => true,
      :did => "value for did",
      :description => "value for description"
    )
  end

  it "should render new form" do
    render "/caller_ids/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", caller_ids_path) do
      with_tag("input#caller_id_did[name=?]", "caller_id[did]")
      with_tag("input#caller_id_description[name=?]", "caller_id[description]")
    end
  end
end


