class AdminController < ApplicationController

  before_filter :checkAdmin

  def index
  end

  def show
  end

  #gets the information needed to show the usersManagement view
  def usersManagement
    @users = User.all

  end

  #gets the information needed to show the invoicesManagement view
  def invoicesManagement
    @invoices = Invoice.all
  end

  #gets the information needed to show the licencesManagement view
  def licencesManagement
    @licences = Licence.all
  end

  #Edit to the Licences
  def editSubscription
    @licence = Licence.find(params[:licenceid])
  end

  def subscriptionsManagement
    @subscriptions = Subscription.find(:all)
  end

  #gets the information needed to show the showUser view
  def showUser
    @user = User.find(params[:userId])
  end

  #gets the information needed to show the showInvoice view
  def showInvoice
    @invoice = Invoice.find(params[:invoiceId])
  end

  #gets the information needed to show the showSubscription view
  def showSubscription
    @subscription = Subscription.find(params[:subscriptionId])
  end

  #gets the information needed to show the editSubscription view
  def editSubscription
    @subscription = Subscription.find(params[:subscriptionId])
  end

  #gets the information needed to show the statistics view
  def statistics
    @numberOfUsers = User.count
  end

  #deletes a user
  def deleteUser
    u = User.find(params[:userId])
    u.deleted = true
    u.save
    redirect_to usersManagement_admin_path
  end

  #deletes an invoice
  def deleteInvoice
    Invoice.find(params[:invoiceId]).destroy
    redirect_to invoicesManagement_admin_path
  end

  #deletes a subscription
  def deleteSubscription
    s = Subscription.find(params[:subscriptionId])
    s.deleted = true
    s.save
    redirect_to subscriptionsManagement_admin_path
  end

  #updates a subscription
  def updateSubscription
    error = false
    if (params[:licence_type] == t('admin.editSubscription.special') and (params[:askNewExpirationDate] or
       params[:askNewTrialExpirationDate]))
      error = true
      #TODO : inline error instead of flash
      flash[:error] = t('admin.updateSubscription.errorSpecialLicence')
    elsif (params[:licence_type] == t('admin.editSubscription.trial') and (params[:askNewExpirationDate] or
        !params[:askNewTrialExpirationDate]))
      error = true
      #TODO : inline error instead of flash
      flash[:error] = t('admin.updateSubscription.errorTrialLicence')
    elsif ((params[:licence_type] == t('admin.subscriptionsManagement.monthly') or
        params[:licence_type] == t('admin.subscriptionsManagement.biannual') or
        params[:licence_type] == t('admin.subscriptionsManagement.videoconference') or
        params[:licence_type] == t('admin.subscriptionsManagement.additional_data')) and
        (!params[:askNewExpirationDate] or params[:askNewTrialExpirationDate]))
      error = true
      #TODO : inline error instead of flash
      flash[:error] = t('admin.updateSubscription.errorLicences')
    end
    if error
      redirect_to editSubscription_admin_path(:subscriptionId => params[:subscriptionId])
    else
      s = Subscription.find(params[:subscriptionId])
      if (params[:status] == t('admin.editSubscription.active'))
        s.status = 0
      elsif (params[:status] == t('admin.editSubscription.incomplete'))
        s.status = 1
      elsif (params[:status] == t('admin.editSubscription.pending'))
        s.status = 2
      elsif (params[:status] == t('admin.editSubscription.cancelled'))
        s.status = 3
      elsif (params[:status] == t('admin.editSubscription.failed'))
        s.status = 4
      elsif (params[:status] == t('admin.editSubscription.trial'))
        s.status = 5
      elsif (params[:status] == t('admin.editSubscription.suspended'))
        s.status = 6
      elsif (params[:status] == t('admin.editSubscription.inactive'))
        s.status = 7
      end
      if (params[:licence_type] == t('admin.editSubscription.special'))
        s.licence_type = 0
        s.expiration_date = nil
        s.trial_expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.trial'))
        s.licence_type = 1
        s.expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.monthly'))
        s.licence_type = 5
        s.trial_expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.biannual'))
        s.licence_type = 10
        s.trial_expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.annual'))
        s.licence_type = 15
        s.trial_expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.videoconference'))
        s.licence_type = 20
        s.trial_expiration_date = nil
      elsif (params[:licence_type] == t('admin.editSubscription.additional_data'))
        s.licence_type = 25
        s.trial_expiration_date = nil
      end
      unless (params[:user_id].nil?)
        begin
          unless (params[:user_id] == "")
            u = User.find(params[:user_id])
          end
        rescue ActiveRecord::RecordNotFound
            error = true
            #TODO : inline error instead of flash
            flash[:error] = t('admin.updateSubscription.ownerUserNotFound')
            redirect_to editSubscription_admin_path(:subscriptionId => params[:subscriptionId])
        end
        unless error
          s.user_id = params[:user_id]
        end
      end
      unless (params[:sponsor_user_id].nil?)
        begin
          unless (params[:sponsor_user_id] == "")
            u = User.find(params[:sponsor_user_id])
          end
        rescue ActiveRecord::RecordNotFound
          error = true
          #TODO : inline error instead of flash
          flash[:error] = t('admin.updateSubscription.sponsorUserNotFound')
          redirect_to editSubscription_admin_path(:subscriptionId => params[:subscriptionId])
        end
        unless error
          s.sponsor_user_id = params[:sponsor_user_id]
        end
      end
      if (params[:askNewExpirationDate])
        expiration_date = Time.utc(params[:expiration_date_year], params[:expiration_date_month],
          params[:expiration_date_day], params[:expiration_date_minute], params[:expiration_date_hour])
        s.expiration_date = expiration_date
      end
      if (params[:deleted])
        s.deleted = true
      else
        s.deleted = false
      end
      if (params[:askNewTrialExpirationDate])
        trial_expiration_date = Time.utc(params[:trial_expiration_date_year], params[:trial_expiration_date_month],
          params[:trial_expiration_date_day], params[:trial_expiration_date_minute], params[:trial_expiration_date_hour])
        s.trial_expiration_date = trial_expiration_date
      end
      s.save
      unless error
        redirect_to subscriptionsManagement_admin_path
      end
    end
  end

  #Updates the used storage of each user
  def updateUsedStorage
    User.all.each do |user|
      user.used_storage = 0
      userFiles = UserFile.where(:user_id => user.id)
      userFiles.each do |uf|
        user.used_storage += uf.asset_file_size
        user.save(false)
      end
    end
    Upload.all.each do |u|
      projectAdmin = User.find(Project.find(u.project_id).user_id)
      projectAdmin.used_storage += u.asset_file_size if u.deleted == 0
      projectAdmin.save(false)
    end
    redirect_to root_path
  end

  def updateCalendarEvents
    calendarEvents = Event.all
    calendarEvents.each do |e|
      e.destroy if (e.calendar_entry_id.nil?)
    end
    tasks = Task.all
    tasks.each do |t|
      e = Event.new
      e.name = t.name
      if (t.start_date.nil? and t.due_on.nil?)
        e.start_at = e.end_at = nil
      elsif (t.start_date.nil?)
        e.start_at = e.end_at = t.due_on.to_datetime
      elsif (t.due_on.nil?)
        e.start_at = e.end_at = t.start_date.to_datetime
      else
        e.start_at = t.start_date.to_datetime
        e.end_at = t.due_on.to_datetime
      end
      e.task_id = t.id
      e.save
    end
    redirect_to root_path
  end

  def update_tasks_priority
    Task.all.each do |t|
      if t.priority.nil?
        t.priority = 1
        t.save
      end
    end
    redirect_to root_path
  end

  def transform_new_tasks_into_opened
    Task.all.each do |t|
      if t.status == 0
        t.status = 1
        t.save
      end
    end
    redirect_to root_path
  end

  def updateLicence
  @licence = Licence.find(params[:id])
  render :text => params.inspect
  return
  if !@licence
    @licence = Licence.new()
    @licence.id = params[:id]
  end
  if !params[:value]
    params[:value] = ""
  end
    #licence.update_attributes(params[:field] => params[:value])
    @license.update_attributes({params[:field] => params[:value]})
  result = params[:value]
  render :text => result
  return
end


  private
    #Checks that the user has admin privileges
    def checkAdmin
      @user = ( User.find_by_login(current_user.login) || User.find_by_id(current_user.id) )
      if (!@user.admin?)
        #TODO : inline error instead of flash
        flash[:error] = t('admin.index.notAdmin')
        redirect_to root_path
      end
    end
end
