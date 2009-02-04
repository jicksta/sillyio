require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/caller_ids/show.html.erb" do
  include CallerIdsHelper
  before(:each) do
    assigns[:caller_id] = @caller_id = stub_model(CallerId,
      :did => "value for did",
      :description => "value for description"
    )
  end

  it "should render attributes in <p>" do
    render "/caller_ids/show.html.erb"
    response.should have_text(/value\ for\ did/)
    response.should have_text(/value\ for\ description/)
  end
end

