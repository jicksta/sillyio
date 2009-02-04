require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/route_rules/index.html.erb" do
  include RouteRulesHelper
  
  before(:each) do
    assigns[:route_rules] = [
      stub_model(RouteRule),
      stub_model(RouteRule)
    ]
  end

  it "should render list of route_rules" do
    render "/route_rules/index.html.erb"
  end
end

