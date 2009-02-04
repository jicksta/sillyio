require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/route_rules/new.html.erb" do
  include RouteRulesHelper
  
  before(:each) do
    assigns[:route_rule] = stub_model(RouteRule,
      :new_record? => true
    )
  end

  it "should render new form" do
    render "/route_rules/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", route_rules_path) do
    end
  end
end


