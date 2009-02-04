require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/route_rules/show.html.erb" do
  include RouteRulesHelper
  before(:each) do
    assigns[:route_rule] = @route_rule = stub_model(RouteRule)
  end

  it "should render attributes in <p>" do
    render "/route_rules/show.html.erb"
  end
end

