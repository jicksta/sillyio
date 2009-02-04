require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CallerIdsController do

  def mock_caller_id(stubs={})
    @mock_caller_id ||= mock_model(CallerId, stubs)
  end
  
  describe "responding to GET index" do

    it "should expose all caller_ids as @caller_ids" do
      CallerId.should_receive(:find).with(:all).and_return([mock_caller_id])
      get :index
      assigns[:caller_ids].should == [mock_caller_id]
    end

    describe "with mime type of xml" do
  
      it "should render all caller_ids as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        CallerId.should_receive(:find).with(:all).and_return(caller_ids = mock("Array of CallerIds"))
        caller_ids.should_receive(:to_xml).and_return("generated XML")
        get :index
        response.body.should == "generated XML"
      end
    
    end

  end

  describe "responding to GET show" do

    it "should expose the requested caller_id as @caller_id" do
      CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
      get :show, :id => "37"
      assigns[:caller_id].should equal(mock_caller_id)
    end
    
    describe "with mime type of xml" do

      it "should render the requested caller_id as xml" do
        request.env["HTTP_ACCEPT"] = "application/xml"
        CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
        mock_caller_id.should_receive(:to_xml).and_return("generated XML")
        get :show, :id => "37"
        response.body.should == "generated XML"
      end

    end
    
  end

  describe "responding to GET new" do
  
    it "should expose a new caller_id as @caller_id" do
      CallerId.should_receive(:new).and_return(mock_caller_id)
      get :new
      assigns[:caller_id].should equal(mock_caller_id)
    end

  end

  describe "responding to GET edit" do
  
    it "should expose the requested caller_id as @caller_id" do
      CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
      get :edit, :id => "37"
      assigns[:caller_id].should equal(mock_caller_id)
    end

  end

  describe "responding to POST create" do

    describe "with valid params" do
      
      it "should expose a newly created caller_id as @caller_id" do
        CallerId.should_receive(:new).with({'these' => 'params'}).and_return(mock_caller_id(:save => true))
        post :create, :caller_id => {:these => 'params'}
        assigns(:caller_id).should equal(mock_caller_id)
      end

      it "should redirect to the created caller_id" do
        CallerId.stub!(:new).and_return(mock_caller_id(:save => true))
        post :create, :caller_id => {}
        response.should redirect_to(caller_id_url(mock_caller_id))
      end
      
    end
    
    describe "with invalid params" do

      it "should expose a newly created but unsaved caller_id as @caller_id" do
        CallerId.stub!(:new).with({'these' => 'params'}).and_return(mock_caller_id(:save => false))
        post :create, :caller_id => {:these => 'params'}
        assigns(:caller_id).should equal(mock_caller_id)
      end

      it "should re-render the 'new' template" do
        CallerId.stub!(:new).and_return(mock_caller_id(:save => false))
        post :create, :caller_id => {}
        response.should render_template('new')
      end
      
    end
    
  end

  describe "responding to PUT udpate" do

    describe "with valid params" do

      it "should update the requested caller_id" do
        CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
        mock_caller_id.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :caller_id => {:these => 'params'}
      end

      it "should expose the requested caller_id as @caller_id" do
        CallerId.stub!(:find).and_return(mock_caller_id(:update_attributes => true))
        put :update, :id => "1"
        assigns(:caller_id).should equal(mock_caller_id)
      end

      it "should redirect to the caller_id" do
        CallerId.stub!(:find).and_return(mock_caller_id(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(caller_id_url(mock_caller_id))
      end

    end
    
    describe "with invalid params" do

      it "should update the requested caller_id" do
        CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
        mock_caller_id.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :caller_id => {:these => 'params'}
      end

      it "should expose the caller_id as @caller_id" do
        CallerId.stub!(:find).and_return(mock_caller_id(:update_attributes => false))
        put :update, :id => "1"
        assigns(:caller_id).should equal(mock_caller_id)
      end

      it "should re-render the 'edit' template" do
        CallerId.stub!(:find).and_return(mock_caller_id(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end

    end

  end

  describe "responding to DELETE destroy" do

    it "should destroy the requested caller_id" do
      CallerId.should_receive(:find).with("37").and_return(mock_caller_id)
      mock_caller_id.should_receive(:destroy)
      delete :destroy, :id => "37"
    end
  
    it "should redirect to the caller_ids list" do
      CallerId.stub!(:find).and_return(mock_caller_id(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(caller_ids_url)
    end

  end

end
