require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/route_rules/edit.html.erb" do
  include RouteRulesHelper
  
  before(:each) do
    assigns[:route_rule] = @route_rule = stub_model(RouteRule,
      :new_record? => false
    )
  end

  it "should render edit form" do
    render "/route_rules/edit.html.erb"
    
    response.should have_tag("form[action=#{route_rule_path(@route_rule)}][method=post]") do
    end
  end
end


