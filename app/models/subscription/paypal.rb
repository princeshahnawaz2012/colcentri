class Subscription

 def process_ipn(params)
    self.paypal_profilestatus = params['profile_status'] if params['profile_status']


    txn_type = params['txn_type']


   # if params["next_payment_date"] and params["next_payment_date"] != "N/A" and txn_type != "recurring_payment_profile_cancel"
   #   exp_date = params["next_payment_date"]
   #   exp_date = Date.parse(exp_date.gsub(/..:..:.. /,'')) # parse date
   #   self.expiration_date = exp_date
   # end


    if txn_type == 'recurring_payment_profile_created' && pending?
      self.status = STATUS[:Active]
    elsif txn_type == "recurring_payment"  # pago realizado
      self.last_payment_date = Date.parse(params['payment_date'].gsub(/..:..:.. /,''))
      # if subscription.status == 'cancelled' there is no next_payment_date
      # BUG - Recurring payment IS NOT every month, it could be every 6 months or every year
      #self.expiration_date = self.last_payment_date + 1.month if not params["next_payment_date"]

      if self.licence_type == LICENCE_TYPE[:biannual]
        self.expiration_date = self.expiration_date + 6.month
      elsif self.licence_type == LICENCE_TYPE[:annual]
        self.expiration_date = self.expiration_date + 1.year
      else
        self.expiration_date = self.expiration_date + 1.month
      end

      # Create new invoice for this payment

    elsif txn_type == 'recurring_payment_profile_cancel'
      self.status = STATUS[:Cancelled]
      self.shopping_cart.invoice.status == Invoice::STATUS[:Failed]
    elsif txn_type == 'recurring_payment_profile_failed'
      self.status = STATUS[:Failed]
      self.shopping_cart.invoice.status == Invoice::STATUS[:Failed]
    end

    self.update_attributes(self)
  end


def manage_recurring_profile_status_call(action)
    @transaction = send_paypal_transaction(
      {
        :method         => 'ManageRecurringPaymentsProfileStatus',
        :PROFILEID      => paypal_profileid,
        :ACTION         => action
      }
    )
  end

  def update_recurring_profile_call
    amt, period, frequency = get_subscription_data

    @transaction = send_paypal_transaction(
      {
        :method           => 'UpdateRecurringPaymentsProfile',
        :PROFILEID        => paypal_profileid,
        :PaymentPeriod    => period,
        :Amount           => amt,
        :AdditionalBillingCycles => frequency
      }
    )

    @transaction
  end

  def send_paypal_transaction(transaction_data)
    transaction_data[:USER]     = paypal_user
    transaction_data[:PWD]      = paypal_pwd
    transaction_data[:SIGNATURE]= paypal_signature
    transaction_data[:SUBJECT]  = paypal_subject


    @caller =  PayPalSDKCallers::Caller.new(false)
    @transaction = @caller.call(transaction_data)
  end


  def update_subscription_data(response)
    @profile_status = response["PROFILESTATUS"]

    self.paypal_profileid     = response["PROFILEID"]
    self.paypal_correlationid = response["CORRELATIONID"]

    self.paypal_profilestatus = @profile_status if @profile_status

    if @profile_status.first == 'ActiveProfile'
      self.status = Subscription::STATUS[:Active]
      self.expiration_date = Time.now + (Subscription::LICENCE_TYPE_FREQUENCY[self.licence_type]).month
    elsif @profile_status.first == 'PendingProfile'
      self.status = Subscription::STATUS[:Pending]
    end

    self.update_attributes(self)
  end

  def paypal_user
    Colcentric.config.paypal.USER
  end

  def paypal_pwd
    Colcentric.config.paypal.PWD
  end

  def paypal_signature
    Colcentric.config.paypal.SIGNATURE
  end

  def paypal_subject
    ""
  end


  private

  def create_invoice(params)
    invoice = invoices.build
    invoice.payment_date = Date.parse(params['payment_date'].gsub(/..:..:.. /,''))
    invoice.iva = self.iva
    invoice.licence_type = self.licence_type
    invoice.profile_status = self.paypal_profilestatus
    invoice.save
  end

end