class VideoconferenceSubscription < ActiveRecord::Base

  belongs_to :user
  belongs_to :shopping_cart

  attr_accessible :status

  STATUS = {:Active => 0, :Incomplete => 1, :Pending => 2, :Cancelled => 3 , :Failed => 4, :Trial => 5, :Suspended => 6, :Inactive => 7}

  AMMOUNT = 50
  PERIOD = 'Month'
  FREQUENCY = 1
  DESCRIPTION = "1 sala de videoconferencia"

  def is_active?
    active? && (expiration_date && (Time.now < expiration_date if expiration_date))
  end


  def active?
    status == STATUS[:Active]
  end


  def get_subscription_data
    [AMMOUNT, PERIOD, FREQUENCY, DESCRIPTION]
  end


  def update_subscription_data(response)
    @profile_status = response["PROFILESTATUS"]

    self.paypal_profileid     = response["PROFILEID"]
    self.paypal_correlationid = response["CORRELATIONID"]

    self.paypal_profilestatus = @profile_status if @profile_status

    if @profile_status.first == 'ActiveProfile'
      self.status = VideoconferenceSubscription::STATUS[:Active]
      self.expiration_date = Time.now + VideoconferenceSubscription::FREQUENCY.month
    elsif @profile_status.first == 'PendingProfile'
      self.status = VideoconferenceSubscription::STATUS[:Pending]
    end

    self.update_attributes(self)
  end



end