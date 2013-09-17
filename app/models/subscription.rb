class Subscription < ActiveRecord::Base
  concerned_with :paypal

  before_destroy :cancel

  # Warning! The first char is in uppercase!
  STATUS = {:Active => 0, :Incomplete => 1, :Pending => 2, :Cancelled => 3 , :Failed => 4, :Trial => 5, :Suspended => 6, :Inactive => 7}

  # Subscription modes
  # always order like this: special - licences - videoconferences - additional_data
  LICENCE_TYPE = {:special => 0,
                  :trial => 1,
                  :monthly => 5,
                  :biannual => 10,
                  :annual => 15,
                  :videoconference => 20,
                  :additional_data => 25 }
  FIRST_LICENCE = LICENCE_TYPE[:monthly]
  LAST_LICENCE = LICENCE_TYPE[:annual]

  LICENCE_TYPE_AMOUNT = {LICENCE_TYPE[:monthly] => 15,
                         LICENCE_TYPE[:biannual] => 75,
                         LICENCE_TYPE[:annual] => 150,
                         LICENCE_TYPE[:videoconference] => 50,
                         LICENCE_TYPE[:addition_data] => 5}

  LICENCE_TYPE_PERIOD = {LICENCE_TYPE[:monthly] => 'Month',
                         LICENCE_TYPE[:biannual] => 'Month',
                         LICENCE_TYPE[:annual] => 'Month',
                         LICENCE_TYPE[:videoconference] => 'Month',
                         LICENCE_TYPE[:additional_data] => 'Month'}

  LICENCE_TYPE_FREQUENCY = {LICENCE_TYPE[:monthly] => 1,
                            LICENCE_TYPE[:biannual] => 6,
                            LICENCE_TYPE[:annual] => 12,
                            LICENCE_TYPE[:videoconference] => 1,
                            LICENCE_TYPE[:addition_data] => 1}
  LICENCE_TYPE_DESCRIPTION = {LICENCE_TYPE[:monthly] => I18n.t('subscriptions.descriptions.monthly'),
                              LICENCE_TYPE[:biannual] => I18n.t('subscriptions.descriptions.biannual'),
                              LICENCE_TYPE[:annual] => I18n.t('subscriptions.descriptions.annual') }

  # TRIAL - 1 month
  TRIAL_PERIOD = 'day'
  TRIAL_BILLING_CYCLES = 15

  IVA = 1.18

  belongs_to :user
  belongs_to :shopping_cart, :class_name => 'ShoppingCart'
  belongs_to :sponsor_user, :class_name => 'User'
  has_one :invitation
  #has_many :invoices

  validates_inclusion_of :status, :in => (0..7)

  scope :active, :conditions => "status = #{STATUS[:Active]}"
  #scope :assigned, :conditions => "user_id is not null"
  #scope :unassigned, :conditions => "user_id is null"
  #scope :invited, :joins => :invitation

  attr_accessible :licence_type, :created_at, :shopping_cart


  def self.assigned
    Subscription.where("user_id is not null") | Subscription.joins(:invitation)
  end

  def self.unassigned
    Subscription.where("user_id is null") - Subscription.joins(:invitation)
  end

  def self.incomplete
    Subscription.where("status = ?", 1)
  end

  # Returns name of the licence
  def get_subscription_name
    [LICENCE_TYPE[licence_type]]
  end

  def get_amount(calc_iva = true)
    amount = LICENCE_TYPE_AMOUNT[licence_type]
    #amount *= IVA if calc_iva && self.iva
  end

  def get_amount_per_month(calc_iva = true)
    amount = LICENCE_TYPE_AMOUNT[licence_type] / Float(LICENCE_TYPE_FREQUENCY[licence_type])
    amount *= IVA if calc_iva && self.iva
    amount
  end

  # Returns license description
  def get_description
    LICENCE_TYPE_DESCRIPTION[licence_type]
  end


  # returns amount, period, frequency
  def get_subscription_data
    [LICENCE_TYPE_AMOUNT[licence_type], LICENCE_TYPE_PERIOD[licence_type], LICENCE_TYPE_FREQUENCY[licence_type], LICENCE_TYPE_DESCRIPTION[licence_type]]
  end

  #returns period, frequency, total billing cycles
  def get_trial_subscription_data
    eval(TRIAL_BILLING_CYCLES.to_s  + '.' + TRIAL_PERIOD)
  end

  def trial?
    licence_type == LICENCE_TYPE[:trial] && (Time.now < trial_expiration_date if trial_expiration_date)
  end

  def paid?
    licence_type == LICENCE_TYPE[:monthly] || licence_type == LICENCE_TYPE[:biannual] || licence_type == LICENCE_TYPE[:annual]
  end

  def special?
    licence_type == LICENCE_TYPE[:special]
  end

  def is_special?
    user.super_admin?
  end

  def user_name
    begin
      user.login
    rescue
      ""
    end

  end

  def full_name
     begin
      user.first_name + ' ' + user.last_name
    rescue
      ""
    end
  end

  def is_active?
    # if cancel it, it will be active for the time we have already paid it --> IT DOES NOT WORK
    (active? && (expiration_date && (Time.now < expiration_date if expiration_date))) || (cancelled? && (expiration_date && (Time.now < expiration_date if expiration_date)))
  end

  def active?
    status == STATUS[:Active]
  end

  def incomplete?
    status == STATUS[:Incomplete]
  end

  def pending?
    status == STATUS[:Pending]
  end

  def failed?
    status == STATUS[:Failed]
  end

  def suspended?
    status == STATUS[:Suspended]
  end

  def cancelled?
    status == STATUS[:Cancelled]
  end


  ###########################################
  # ACTIONS
  ###########################################


  def start_trial
    status = Subscription::STATUS[:Trial]
    #trial_expiration_date = (DateTime.now + get_trial_subscription_data).to_formatted_s(:db)
  end

  def assign_user(assigned_user)
    # check that this is a sponsorized subscription
    return false unless sponsor_user

    update_attribute(:user, assigned_user)
  end

  def unassign_user
    # check that this is a sponsorized subscription
    return false unless sponsor_user or invitation

    # Make a new incomplete subscription for the user, so he wont have another trial period for free
    subscription = user.build_subscription
    subscription.start_trial
    subscription.save

    update_attribute(:user, nil)
    invitation.update_attribute(:subscription, nil) if invitation
  end

  def update_licence_type(subscription)
    self.update_attributes(subscription)
    @transaction = update_recurring_profile_call
    @transaction.success?
  end

  def update_status(status)
    update_attribute(:status, status)
  end

  def cancel
    if status == STATUS[:Active] || status == STATUS[:Suspended] || status == STATUS[:Pending]
      @transaction = manage_recurring_profile_status_call('Cancel')
      if @transaction.success?
        update_subscription_data(@transaction.response)
        self.update_attribute(:status, STATUS[:Cancelled])
      end
    elsif status == STATUS[:Trial]
      self.update_attribute(:status, STATUS[:Trial])
    end
  end

  def suspend
    @transaction = manage_recurring_profile_status_call('Suspend')
    if @transaction.success?
      update_subscription_data(@transaction.response)
      self.update_attribute(:status, STATUS[:Suspended])
    end
  end

  def reactivate
    @transaction = manage_recurring_profile_status_call('Reactivate')
    if @transaction.success?
      update_subscription_data(@transaction.response)
      self.update_attribute(:status, STATUS[:Active])
    end
  end

end
