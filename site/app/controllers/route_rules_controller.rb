class RouteRulesController < ApplicationController
  # GET /route_rules
  # GET /route_rules.xml
  def index
    @route_rules = RouteRule.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @route_rules }
    end
  end

  # GET /route_rules/1
  # GET /route_rules/1.xml
  def show
    @route_rule = RouteRule.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @route_rule }
    end
  end

  # GET /route_rules/new
  # GET /route_rules/new.xml
  def new
    @route_rule = RouteRule.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @route_rule }
    end
  end

  # GET /route_rules/1/edit
  def edit
    @route_rule = RouteRule.find(params[:id])
  end

  # POST /route_rules
  # POST /route_rules.xml
  def create
    @route_rule = RouteRule.new(params[:route_rule])

    respond_to do |format|
      if @route_rule.save
        flash[:notice] = 'RouteRule was successfully created.'
        format.html { redirect_to(@route_rule) }
        format.xml  { render :xml => @route_rule, :status => :created, :location => @route_rule }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @route_rule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /route_rules/1
  # PUT /route_rules/1.xml
  def update
    @route_rule = RouteRule.find(params[:id])

    respond_to do |format|
      if @route_rule.update_attributes(params[:route_rule])
        flash[:notice] = 'RouteRule was successfully updated.'
        format.html { redirect_to(@route_rule) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @route_rule.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /route_rules/1
  # DELETE /route_rules/1.xml
  def destroy
    @route_rule = RouteRule.find(params[:id])
    @route_rule.destroy

    respond_to do |format|
      format.html { redirect_to(route_rules_url) }
      format.xml  { head :ok }
    end
  end
end
