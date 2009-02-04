require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RouteRulesController do

  def mock_route_rule(stubs={})
    @mock_route_rule ||= mock_model(RouteRule, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all route_rules as @route_rules" do
      RouteRule.should_receive(:find).with(:all).and_return([mock_route_rule])
      get :index
      assigns[:route_rules].should == [mock_route_rule]
    end

    describe "with mime type of xml" do
  
      it "should render all route_rules as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        RouteRule.should_receive(:find).with(:all).and_return(route_rules = mock("Array of RouteRules"))
        route_rules.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested route_rule as @route_rule" do
      RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
      get :show, :id => "37"
      assigns[:route_rule].should equal(mock_route_rule)
    end
    
    describe "with mime type of xml" do

      it "should render the requested route_rule as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
        mock_route_rule.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new route_rule as @route_rule" do
      RouteRule.should_receive(:new).and_return(mock_route_rule)
      get :new
      assigns[:route_rule].should equal(mock_route_rule)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested route_rule as @route_rule" do
      RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
      get :edit, :id => "37"
      assigns[:route_rule].should equal(mock_route_rule)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created route_rule as @route_rule" do
        RouteRule.should_receive(:new).with({'these' => 'params'}).and_return(mock_route_rule(:save => true))
        post :create, :route_rule => {:these => 'params'}
        assigns(:route_rule).should equal(mock_route_rule)
      end

      it "should redirect to the created route_rule" do
        RouteRule.stub!(:new).and_return(mock_route_rule(:save => true))
        post :create, :route_rule => {}
        response.should redirect_to(route_rule_url(mock_route_rule))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved route_rule as @route_rule" do
        RouteRule.stub!(:new).with({'these' => 'params'}).and_return(mock_route_rule(:save => false))
        post :create, :route_rule => {:these => 'params'}
        assigns(:route_rule).should equal(mock_route_rule)
      end

      it "should re-render the 'new' template" do
        RouteRule.stub!(:new).and_return(mock_route_rule(:save => false))
        post :create, :route_rule => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested route_rule" do
        RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
        mock_route_rule.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :route_rule => {:these => 'params'}
      end

      it "should expose the requested route_rule as @route_rule" do
        RouteRule.stub!(:find).and_return(mock_route_rule(:update_attributes => true))
        put :update, :id => "1"
        assigns(:route_rule).should equal(mock_route_rule)
      end

      it "should redirect to the route_rule" do
        RouteRule.stub!(:find).and_return(mock_route_rule(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(route_rule_url(mock_route_rule))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested route_rule" do
        RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
        mock_route_rule.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :route_rule => {:these => 'params'}
      end

      it "should expose the route_rule as @route_rule" do
        RouteRule.stub!(:find).and_return(mock_route_rule(:update_attributes => false))
        put :update, :id => "1"
        assigns(:route_rule).should equal(mock_route_rule)
      end

      it "should re-render the 'edit' template" do
        RouteRule.stub!(:find).and_return(mock_route_rule(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested route_rule" do
      RouteRule.should_receive(:find).with("37").and_return(mock_route_rule)
      mock_route_rule.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the route_rules list" do
      RouteRule.stub!(:find).and_return(mock_route_rule(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(route_rules_url)
    end

  end

end
