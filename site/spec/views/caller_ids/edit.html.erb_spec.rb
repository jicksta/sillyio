require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/caller_ids/edit.html.erb" do
  include CallerIdsHelper
  
  before(:each) do
    assigns[:caller_id] = @caller_id = stub_model(CallerId,
      :new_record? => false,
      :did => "value for did",
      :description => "value for description"
    )
  end

  it "should render edit form" do
    render "/caller_ids/edit.html.erb"
    
    response.should have_tag("form[action=#{caller_id_path(@caller_id)}][method=post]") do
      with_tag('input#caller_id_did[name=?]', "caller_id[did]")
      with_tag('input#caller_id_description[name=?]', "caller_id[description]")
    end
  end
end


