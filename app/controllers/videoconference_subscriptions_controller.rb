class VideoconferenceSubscriptionsController < ApplicationController
  # GET /videoconference_subscriptions
  # GET /videoconference_subscriptions.xml
  def index
    @videoconference_subscriptions = VideoconferenceSubscription.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @videoconference_subscriptions }
    end
  end

  # GET /videoconference_subscriptions/1
  # GET /videoconference_subscriptions/1.xml
  def show
    @videoconference_subscription = VideoconferenceSubscription.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @videoconference_subscription }
    end
  end

  # GET /videoconference_subscriptions/new
  # GET /videoconference_subscriptions/new.xml
  def new
    @videoconference_subscription = VideoconferenceSubscription.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @videoconference_subscription }
    end
  end

  # GET /videoconference_subscriptions/1/edit
  def edit
    @videoconference_subscription = VideoconferenceSubscription.find(params[:id])
  end

  # POST /videoconference_subscriptions
  # POST /videoconference_subscriptions.xml
  def create
    @videoconference_subscription = VideoconferenceSubscription.new(params[:videoconference_subscription])

    respond_to do |format|
      if @videoconference_subscription.save
        format.html { redirect_to(@videoconference_subscription, :notice => 'Videoconference subscription was successfully created.') }
        format.xml  { render :xml => @videoconference_subscription, :status => :created, :location => @videoconference_subscription }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @videoconference_subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /videoconference_subscriptions/1
  # PUT /videoconference_subscriptions/1.xml
  def update
    @videoconference_subscription = VideoconferenceSubscription.find(params[:id])

    respond_to do |format|
      if @videoconference_subscription.update_attributes(params[:videoconference_subscription])
        format.html { redirect_to(@videoconference_subscription, :notice => 'Videoconference subscription was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @videoconference_subscription.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /videoconference_subscriptions/1
  # DELETE /videoconference_subscriptions/1.xml
  def destroy
    @videoconference_subscription = VideoconferenceSubscription.find(params[:id])
    @videoconference_subscription.destroy

    respond_to do |format|
      format.html { redirect_to(videoconference_subscriptions_url) }
      format.xml  { head :ok }
    end
  end
end
