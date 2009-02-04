class CallerIdsController < ApplicationController
  # GET /caller_ids
  # GET /caller_ids.xml
  def index
    @caller_ids = CallerId.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @caller_ids }
    end
  end

  # GET /caller_ids/1
  # GET /caller_ids/1.xml
  def show
    @caller_id = CallerId.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @caller_id }
    end
  end

  # GET /caller_ids/new
  # GET /caller_ids/new.xml
  def new
    @caller_id = CallerId.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @caller_id }
    end
  end

  # GET /caller_ids/1/edit
  def edit
    @caller_id = CallerId.find(params[:id])
  end

  # POST /caller_ids
  # POST /caller_ids.xml
  def create
    @caller_id = CallerId.new(params[:caller_id])

    respond_to do |format|
      if @caller_id.save
        flash[:notice] = 'CallerId was successfully created.'
        format.html { redirect_to(@caller_id) }
        format.xml  { render :xml => @caller_id, :status => :created, :location => @caller_id }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @caller_id.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /caller_ids/1
  # PUT /caller_ids/1.xml
  def update
    @caller_id = CallerId.find(params[:id])

    respond_to do |format|
      if @caller_id.update_attributes(params[:caller_id])
        flash[:notice] = 'CallerId was successfully updated.'
        format.html { redirect_to(@caller_id) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @caller_id.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /caller_ids/1
  # DELETE /caller_ids/1.xml
  def destroy
    @caller_id = CallerId.find(params[:id])
    @caller_id.destroy

    respond_to do |format|
      format.html { redirect_to(caller_ids_url) }
      format.xml  { head :ok }
    end
  end
end
