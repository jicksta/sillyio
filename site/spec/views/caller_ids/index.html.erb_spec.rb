require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/caller_ids/index.html.erb" do
  include CallerIdsHelper
  
  before(:each) do
    assigns[:caller_ids] = [
      stub_model(CallerId,
        :did => "value for did",
        :description => "value for description"
      ),
      stub_model(CallerId,
        :did => "value for did",
        :description => "value for description"
      )
    ]
  end

  it "should render list of caller_ids" do
    render "/caller_ids/index.html.erb"
    response.should have_tag("tr>td", "value for did".to_s, 2)
    response.should have_tag("tr>td", "value for description".to_s, 2)
  end
end

