class ShoppingCart


  def set_express_checkout(cancelURL, returnURL, locale, ammount, number = 1)
    @transaction = set_express_checkout_call(cancelURL, returnURL, locale, ammount, number)
  end


  def get_ec_details(token, payerid = nil)
    @transaction = get_ec_details_call(token, payerid)
  end


  def create_recurring(token, payerid, subscription, ammount, current = 0, video = false)

    if video
      user_name = subscription.user
    else
      if subscription.user
        user_name = subscription.user.name
      elsif subscription.sponsor_user
        user_name = subscription.sponsor_user.name
      else
        user_name = user.name
      end

    end

    start_date = subscription.expiration_date.to_formatted_s(:db) if subscription.expiration_date && (subscription.expiration_date > Date.current)
    start_date = start_date || Time.current.to_formatted_s(:db)
    @transaction = create_recurring_call(token, payerid, subscription, current, user_name, start_date, ammount)

    if @transaction.success?
      subscription.update_subscription_data(@transaction.response)
    end

    return @transaction
  end


  def paypal_ec_url
    Colcentric.config.paypal.EC_URL
  end

  def paypal_dev_central_url
    Colcentric.config.paypal.DEV_CENTRAL_URL
  end


  private

  def set_express_checkout_call(cancelURL, returnURL, locale, ammount, number)
    req = {  :method                 		=> 'SetExpressCheckout',
            :AMT                        => ammount,
            :SOLUTIONTYPE               => 'Sole',
            :paymentaction              => 'Sale',
            :currencycode           		=> 'EUR',
            :LANDINGPAGE                => 'Billing',
            :LOCALECODE                 => locale,
            :cancelurl              		=> cancelURL,
            :returnurl              		=> returnURL,
            :brandname                  => "Colcentric Tecnología e Innovación, SL"
            #:hdrimg                     => "http://colcentric.com/LogoCCPaypal.jpg",
            #:hdrimg                     => "http://pro.colcentric.com/images/LogoColcentric1.png",
            #:hdrbordercolor             => "b32727",
            #:hdrbackcolor               => "ffffff",
            #:payflowcolor               => "ffffff"
    }

    number.times{|i|
      req[:"L_BILLINGTYPE#{i}"] = 'RecurringPayments'
      req[:"L_BILLINGAGREEMENTDESCRIPTION#{i}"] = description#'Subscription to Colcentric'
      #req[:"L_CUSTOM#{i}"] = 'custom'
      req[:"L_ITEMCATEGORY#{i}"] = 'Physical'
    }

    @transaction = send_paypal_transaction(req)
  end

  def get_ec_details_call(token, payerid)
    req =  {
        :method => 'GetExpressCheckoutDetails',
        :token  => token
      }
    req[:payerid] = payerid if payerid

    @transaction = send_paypal_transaction(req)
  end

  def create_recurring_call(token, payerid, subscription, current, user_name, profile_start_date, amt)
    amt_old, period, frequency, desc = subscription.get_subscription_data

    # TO DO - Custom description

    req = {
        :method                   => 'CreateRecurringPaymentsProfile',
        :token                    => token,
        :payerid                  => payerid,
        :AMT                      => amt,
        :currencycode             => 'EUR',
        :countrycode              => 'ES',
        :DESC                     => description,
        :PROFILESTARTDATE         => profile_start_date,
        :SUBSCRIBERNAME           => user_name,
        :BILLINGPERIOD            => period,
        :BILLINGFREQUENCY         => frequency,
        :"L_PAYMENTREQUEST_0_NAME#{current}" => description,
        :"L_PAYMENTREQUEST_0_AMT#{current}"  => amt,
        :"L_PAYMENTREQUEST_0_QTY#{current}"  => '1',
        :"L_PAYMENTREQUEST_0_DESC#{current}" => full_description(user_name),
        :"L_PAYMENTREQUEST_0_ITEMCATEGORY#{current}" => 'Physical'
      }

    @transaction = send_paypal_transaction(req)

    return @transaction
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


  def description
    I18n.t('subscriptions.paypal.description')
  end

  def full_description(user_name)
    I18n.t('subscriptions.paypal.full_description', :user => user_name)
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

end