require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CallerIdsController do
  describe "route generation" do
    it "should map #index" do
      route_for(:controller => "caller_ids", :action => "index").should == "/caller_ids"
    end
  
    it "should map #new" do
      route_for(:controller => "caller_ids", :action => "new").should == "/caller_ids/new"
    end
  
    it "should map #show" do
      route_for(:controller => "caller_ids", :action => "show", :id => 1).should == "/caller_ids/1"
    end
  
    it "should map #edit" do
      route_for(:controller => "caller_ids", :action => "edit", :id => 1).should == "/caller_ids/1/edit"
    end
  
    it "should map #update" do
      route_for(:controller => "caller_ids", :action => "update", :id => 1).should == "/caller_ids/1"
    end
  
    it "should map #destroy" do
      route_for(:controller => "caller_ids", :action => "destroy", :id => 1).should == "/caller_ids/1"
    end
  end

  describe "route recognition" do
    it "should generate params for #index" do
      params_from(:get, "/caller_ids").should == {:controller => "caller_ids", :action => "index"}
    end
  
    it "should generate params for #new" do
      params_from(:get, "/caller_ids/new").should == {:controller => "caller_ids", :action => "new"}
    end
  
    it "should generate params for #create" do
      params_from(:post, "/caller_ids").should == {:controller => "caller_ids", :action => "create"}
    end
  
    it "should generate params for #show" do
      params_from(:get, "/caller_ids/1").should == {:controller => "caller_ids", :action => "show", :id => "1"}
    end
  
    it "should generate params for #edit" do
      params_from(:get, "/caller_ids/1/edit").should == {:controller => "caller_ids", :action => "edit", :id => "1"}
    end
  
    it "should generate params for #update" do
      params_from(:put, "/caller_ids/1").should == {:controller => "caller_ids", :action => "update", :id => "1"}
    end
  
    it "should generate params for #destroy" do
      params_from(:delete, "/caller_ids/1").should == {:controller => "caller_ids", :action => "destroy", :id => "1"}
    end
  end
end
