class ShoppingCart < ActiveRecord::Base
  concerned_with :paypal

  belongs_to :user
  has_many :subscriptions
  has_one :videoconference_subscription
  has_one :invoice


  # less than videoconference key is any kind of licence
  scope :licences, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type < ?', Subscription::LICENCE_TYPE[:videoconference]]

  scope :monthlys, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type = ?', Subscription::LICENCE_TYPE[:monthly]]
  scope :biannuals, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type = ?', Subscription::LICENCE_TYPE[:biannual]]
  scope :annuals, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type = ?', Subscription::LICENCE_TYPE[:annual]]

  scope :videoconfereces, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type = ?', Subscription::LICENCE_TYPE[:videoconference]]
  scope :additional_datas, :joins => :subscriptions,
    :conditions => ['subscriptions.licence_type = ?', Subscription::LICENCE_TYPE[:additional_datas]]

  attr_accessible :susbscriptions, :ammount, :invoice



  def licences
    subscriptions.where(:status => Subscription::STATUS[:Incomplete])
  end

  def incomplete_monthly_licences
     subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:monthly], Subscription::STATUS[:Incomplete])
  end

  def incomplete_biannual_licences
    subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:biannual], Subscription::STATUS[:Incomplete])
  end

  def incomplete_annual_licences
     subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:annual], Subscription::STATUS[:Incomplete])
  end

  def incomplete_videoconference_subscription
    videoconference_subscription if videoconference_subscription and videoconference_subscription.status == VideoconferenceSubscription::STATUS[:Incomplete]
  end

  def incomplete_videoconference_subscriptions
    videoconference_subscriptions.where("status = ?", VideoconferenceSubscription::STATUS[:Incomplete] )
  end


  def monthly_licences
    subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:monthly], Subscription::STATUS[:Active])
  end

  def biannual_licences
    subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:biannual], Subscription::STATUS[:Active])
  end

  def annual_licences
    subscriptions.where("licence_type = ? and status = ?", Subscription::LICENCE_TYPE[:annual], Subscription::STATUS[:Active])
  end

  def additional_datas
    subscriptions.where(:licence_type => Subscription::LICENCE_TYPE[:additional_data])
  end

  # Should this shopping cart apply IVA?
  def apply_iva?
    invoice = Invoice.last
    invoice.apply_iva
    #invoice.iva == nil || invoice.iva == ''
   end

  # Gets total ammount without IVA
  def total_ammount_without_iva
    total = 0.0
    licences.each do |s|
      total += s.get_amount
    end
    if incomplete_videoconference_subscription
      total += VideoconferenceSubscription::AMMOUNT
    end
    total.round(2)
  end

  # Gets total ammount (with or without IVA) of all licenses purchased in current shopping cart
  def total_ammount
    ammount = total_ammount_without_iva
    if self.apply_iva?
        (ammount * 1.18).round(2)
    else
        ammount.round(2)
    end
  end

  def get_iva(ammount)
    if apply_iva?
      (ammount * 0.18).round(2)
    else
      0.0
    end
  end

  def clear_subscriptions
    if videoconference_subscription and videoconference_subscription.status == VideoconferenceSubscription::STATUS[:Incomplete]
      videoconference_subscription.destroy
    elsif videoconference_subscription and not videoconference_subscription.status == VideoconferenceSubscription::STATUS[:Active]
      videoconference_subscription.shopping_cart = nil
    end

    subscriptions.each do |s|
      if s.status == Subscription::STATUS[:Incomplete]
        s.destroy
      else
        s.shopping_cart = nil
      end
    end
  end

end
