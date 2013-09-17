
class SubscriptionsController < ApplicationController
  before_filter :load_subscription, :except => [:new, :error, :exception]
  before_filter :check_subscription_done, :only => [:update]
  before_filter :check_subscription_pending, :only => [:index, :update]
  skip_before_filter :subscription_done?, :load_project
  skip_before_filter :set_locale,
                :rss_token,
                :set_client,
                :confirmed_user?,
                :subscription_done?,
                :load_project,
                :load_organizations,
                :login_required,
                :touch_user,
                :belongs_to_project?,
                :load_community_organization,
                :add_chrome_frame_header,
                :load_subscription,
                :verify_authenticity_token,:only => [:ipn]


  def ipn
    Paypal::Notification.ipn_url = "https://www.paypal.com/cgi-bin/webscr" if Rails.env == "production"

    @notify = Paypal::Notification.new(request.raw_post)
    if @notify.acknowledge
      params = @notify.params
      if @subscription = Subscription.find_by_paypal_profileid(params['recurring_subscription_id'])
        @subscription.process_ipn(params)
      end
      # for debugging in the future
      logger.error(@notify)
    else
      logger.error("Failed to verify Paypal's notification, please investigate")
    end

    render :nothing => true
  end

  def pending
  end

  def error
    # TO DO
    #redirect_to buy_shopping_carts_path
    #render session[:paypal_error]
    #redirect_to root_path
  end

  def index
    @subscription = current_user.subscription
    @sponsor_subscriptions = current_user.sponsor_subscriptions.order("licence_type").active.assigned
    @sponsor_subscriptions_unassigned = current_user.sponsor_subscriptions.order("licence_type").active.unassigned.group_by(&:licence_type)
    @videoconference_subscriptions = current_user.videoconference_subscriptions
    @num_videoconferences = current_user.num_videoconferences
    @sub_actual = self
  end


  def new
    if current_user.super_admin?
      @subscription = current_user.build_subscription
      @subscription.status = Subscription::STATUS[:Active]
      @subscription.licence_type = Subscription::LICENCE_TYPE[:special]
      if @subscription.save

        redirect_to root_path
      end
    else
      @subscription = current_user.build_subscription
      @subscription.start_trial
      if @subscription.save
        redirect_to root_path
      else
        redirect_to error_subscription_path
        #redirect_to root_path
      end
    end
  end

  def update
    current_user.subscription.cancel
    #current_user.subscription.update_licence_type(params[:subscription])
    #current_user.subscription.update_attributes(params[:subscription])
    flash[:success] = t('subscriptions.update.update')
    redirect_to :action => "buy"

    #if current_user.subscription.update_licence_type(params[:subscription])
    #  flash[:success] = t('subscriptions.update.updated')
    #  redirect_to :action => "index"
    #else
    #  flash.now[:error] = t('subscriptions.update.error')
    #  redirect_to :action => 'index'
    #end
  end

  def create_sponsors
#    if current_user.super_admin?
#      Integer(params["quantity"]).times {
#        @sponsor = current_user.sponsor_subscriptions.build
#        @sponsor.status = Subscription::STATUS[:Active]
#        @sponsor.licence_type = Subscription::LICENCE_TYPE[:special]
#        @sponsor.save
#      }
#      redirect_to subscriptions_path()
#    else
#      session[:sponsor] = params["quantity"]
#      @sponsor = current_user.sponsor_subscriptions.build
#      @sponsor.status = Subscription::STATUS[:Incomplete]
#      @sponsor.save
#      redirect_to buy_subscription_path(@sponsor)
#    end

    @sponsor = current_user.sponsor_subscriptions.build
    @sponsor.status = Subscription::STATUS[:Incomplete]
    @sponsor.save
    redirect_to buy_subscription_path(@sponsor)
  end

  def assign_sponsors
    user_or_email = params[:user_or_email]
    licence = params[:licence_type]
    #@targets = user_or_email.extract_emails
    @targets = user_or_email.split( /, */ )

    #assign = true
    @targets.each do |target|
      #assign = assign and
      assign_sponsor_subscription(target, licence)
    end


    if not flash.has_key?(:error) and @targets.count > 0

      if @targets.count == 1
        flash[:success] = t('subscriptions.assign_sponsor.success_one')
      else
        flash[:success] = t('subscriptions.assign_sponsor.success_many')
      end
    end


    redirect_to subscriptions_path
  end

  def unassign_sponsor
    @subscription.unassign_user
    redirect_to subscriptions_path
  end

  def cancel
    if @subscription.cancel
      flash[:success] = t('subscriptions.edit.cancel_ok')
      redirect_to :action => 'index'
      #redirect_to subscription_path(@subscription)
    else
      flash[:error] = t('subscriptions.edit.cancel_failed')
      redirect_to :action => 'index'
    end
  end

  def reactivate
    if @subscription.reactivate
      flash[:success] = t('subscriptions.edit.reactivate_ok')
    else
      flash[:error] = t('subscriptions.edit.reactivate_failed')
    end
    redirect_to :action => 'index'
  end

  def suspend
    if @subscription.suspend
      flash[:success] = t('subscriptions.edit.suspend_ok')
    else
      flash[:error] = t('subscriptions.edit.suspend_failed')
    end
    redirect_to :action => 'index'
  end

  def destroy
    authorize! :destroy, @subscription
    if @subscription.destroy
      flash[:success] = t('subscriptions.index.destroyed')
    else
      flash[:error] = t('subscriptions.index.destroy_error')
    end
    redirect_to subscriptions_path
  end


  private

  def load_subscription
    @subscription = Subscription.find_by_id(params[:id]) || current_user.subscription

    if !@subscription
      #if @subscription.user == current_user
      #  return true
      #end
      redirect_to new_subscription_path
    end
  end

  def check_subscription_done
    if @subscription && !(@subscription.trial? || @subscription.is_active? || @subscription.pending?)
      redirect_to subscription_path(@subscription)
    end
  end

  def check_subscription_pending
    if @subscription.pending?
      redirect_to pending_subscription_path(@subscription)
    end
  end

  def assign_sponsor_subscription(login_or_email, licence)

    free_sponsors = current_user.sponsor_subscriptions.active.where("user_id is null and licence_type = ?", licence)
    @sponsor = free_sponsors.first if free_sponsors

    user = User.find_by_username_or_email(login_or_email)

    if @sponsor && user
      if user.subscription
        if user.has_paid_license?
          flash[:error] = t('subscriptions.index.user_already_has_a_subscription', :user => login_or_email)
          return false
        else
          user.subscription.destroy
        end
      end
      @sponsor.assign_user(user)
    elsif @sponsor
      flash[:error] = t('subscriptions.index.user_does_not_exist', :user => login_or_email)
      return false
    elsif !@sponsor
      flash[:error] = t('subscriptions.index.not_enough_sponsors', :user => login_or_email)
      return false
    else
      return false
    end

    return true

  end


end
