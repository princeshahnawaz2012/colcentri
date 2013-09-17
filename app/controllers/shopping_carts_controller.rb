class ShoppingCartsController < ApplicationController
  before_filter :load_shopping_cart
  skip_before_filter :subscription_done?, :load_project

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |f|
      flash[:error] = t('common.not_allowed')
      f.any(:html, :m) { redirect_to subscriptions_path }
      handle_api_error(f, @subscription)
    end
  end

  def index
    render :buy
  end


  # Destroys incomplete licenses and invoices before shopping
  def buy
    @shopping.clear_subscriptions
    current_user.clear_invoices
  end

  # Not used
  # Updates total and sub-total of shopping_cart -> buy page
  def update_total
    respond_to do |page|
      page.replace_html 'divinicial', 'Hello world!'
    end
  end


# SetExpressCheckout API call
  def set_checkout

    @ECRedirectURL = @shopping.paypal_ec_url

    host=request.host.to_s
    port=request.port.to_s
   # cancelURL="http://#{host}:#{port}"
   # returnURL="http://#{host}:#{port}/shopping/#{@shopping.id}/get_details"

    cancelURL= "http://pro.kinubi.com"
    returnURL = "http://pro.kinubi.com/shopping/#{@shopping.id}/get_details"

    #Check for quantity
    shopping_params = params["shopping_cart"]
    @monthly_quantity = Integer(shopping_params["monthly_licences"]["quantity"])
    @biannual_quantity = Integer(shopping_params["biannual_licences"]["quantity"])
    @annual_quantity = Integer(shopping_params["annual_licences"]["quantity"])
    @licences_quantity = @monthly_quantity + @biannual_quantity + @annual_quantity
    @videoconference_quantity = Integer(shopping_params["videoconference"]["quantity"])
    #additional_data_quantity = Integer(shopping_params["additional_data"]["quantity"])
    @total_quantity = @licences_quantity + @videoconference_quantity #+ additional_data_quantity

    if not can_user_purchase_more_videoconferences
    #if @videoconference_quantity == 1 and current_user.has_videoconference_subscription?
      flash.now[:error] = t('shopping_carts.buy.error_videoconference')
      render :buy
      return
    end

   self.save




    @transaction = @shopping.set_express_checkout(cancelURL, returnURL, current_user.locale, @ammount, @total_quantity)


    if current_user.super_admin? # Special licenses created, so the transaction is OK.
      redirect_to subscriptions_path()
    elsif @transaction && @transaction.success?
      @token = @transaction.response["TOKEN"].to_s
      session[:token] = @token
      redirect_to(@ECRedirectURL+@token)
    elsif not current_user.super_admin?
      session[:paypal_error]=@transaction.response
      redirect_to :action => 'error'
      return
    end
    rescue Errno::ENOENT => exception
        flash[:error] = exception
        redirect_to :action => 'exception'

  end


  def can_user_purchase_more_videoconferences

    if current_user.num_videoconferences + @videoconference_quantity > 10
      false
    else
      true
    end

  end

  def save

    shopping_params = params["shopping_cart"]

    if current_user.super_admin?
      (@licences_quantity).times {
        subscription = current_user.sponsor_subscriptions.build
        subscription.shopping_cart = @shopping
        subscription.status = Subscription::STATUS[:Active]
        subscription.licence_type = Subscription::LICENCE_TYPE[:special]
        subscription.save
      }

      (@videoconference_quantity).times {
        videoconference = current_user.videoconference_subscription.new
        videoconference.status = VideoconferenceSubscription::STATUS[:Active]
        videoconference.shopping_cart = @shopping
        videoconference.save
      }
      #redirect_to subscriptions_path()
      #return

    else

      @ammount = 0.0
      @annual_quantity.times do
        create_incomplete_subscription(Subscription::LICENCE_TYPE[:annual])
        @ammount += Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:annual]]
      end
      @biannual_quantity.times do
        create_incomplete_subscription(Subscription::LICENCE_TYPE[:biannual])
        @ammount += Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:biannual]]
      end
      @monthly_quantity.times do
        create_incomplete_subscription(Subscription::LICENCE_TYPE[:monthly])
        @ammount += Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:monthly]]
      end
      @videoconference_quantity.times do
        create_incomplete_videoconference_subscription
        @ammount += VideoconferenceSubscription::AMMOUNT
      end

      invoice_params = shopping_params["invoice"]
      save_invoice(invoice_params)

    end

  end


  # Generates and saves current invoice
  def save_invoice(invoice_data)
    @invoice = current_user.invoices.new
    @invoice.shopping_cart_id = params[:id]
    @invoice.status = Invoice::STATUS[:Incomplete]
    @invoice.invoice_type = invoice_data["invoice_type"]
    @invoice.promotional_code = invoice_data["promotional_code"]
    @invoice.first_name = invoice_data["first_name"]
    @invoice.last_name = invoice_data["last_name"]
    @invoice.organization = invoice_data["organization"]
    @invoice.phone = invoice_data["phone"]
    @invoice.email = invoice_data["email"]
    @invoice.country = invoice_data["country"]
    @invoice.address = invoice_data["address"]
    @invoice.city = invoice_data["city"]
    @invoice.postal_code = invoice_data["postal_code"]
    @invoice.n_monthly_licenses = @monthly_quantity
    @invoice.n_biannual_licenses = @biannual_quantity
    @invoice.n_annual_licenses = @annual_quantity
    @invoice.n_videoconferences = @videoconference_quantity

    @invoice.invoice_number = invoice_number

    iva = invoice_data["iva_country"] + invoice_data["iva_number"]
    @invoice.iva = iva
    #iva = invoice_data["iva_number"]

    calculate_iva(iva)

    if @invoice.apply_iva
      @ammount = @ammount * 1.18
    end

    @invoice.ammount = @ammount
    @invoice.save

  end


  # Generates invoices number
  def invoice_number

    last_invoice = Invoice.all.last

    if last_invoice

      num_last_invoice = last_invoice.invoice_number

      num_invoice = num_last_invoice[-6,6]
      year_invoice = num_last_invoice[0..1]

      year_invoice2 = "20" + year_invoice
      current_year = Time.now.year

      if year_invoice2.to_s != current_year.to_s # Change year and restart number
        year_invoice = year_invoice.to_i + 1
        num_invoice = Invoice::STARTING_INVOICE_NUMBER
      else
        num_invoice = num_invoice.to_i + 1
        num_invoice = num_invoice.to_s

        # Fill in with 0's'
        (1..(6 - num_invoice.length)).each do |number|
          num_invoice = "0" + num_invoice
        end
      end

      invoice_number = year_invoice.to_s + "-" + num_invoice.to_s
    else
      invoice_number = Invoice::FIRST_INVOICE_YEAR + "-" + Invoice::FIRST_INVOICE_NUMBER
    end
  end



  def calculate_iva(iva_number)

     if @invoice.invoice_type == Invoice::TYPE[:particular]
       if EU_country?(@invoice.country)
         @invoice.apply_iva = true
       else
         @invoice.apply_iva = false
       end
     else
       if @invoice.country != '' and not EU_country?(@invoice.country)
         @invoice.apply_iva = false
       elsif @invoice.country == "ES"
         if Canarias_Ceuta_or_Melilla_PC?(@invoice.postal_code)
           @invoice.apply_iva = false
         else
           @invoice.apply_iva = true
         end
       else # European Union country (not Spain)
         if vat_valid?(iva_number)
           @invoice.apply_iva = false
         else
           @invoice.apply_iva = true
         end

       end
     end
   end


  # Is the given country member of the European Union?
  def EU_country?(code)
    Invoice::EUROPEAN_UNION_COUNTRIES_CODES.each_pair do |k,v|
      return true if code == v
    end
    return false

  end

  # Is the given postal code from Canarias, Ceuta or Melilla?
  def Canarias_Ceuta_or_Melilla_PC?(postal_code)


    first, second =  postal_code.to_s.split('')

    if first.nil? or second.nil?
      return false
    else
      first_two_digits = (first + second).to_i

      if first_two_digits == Invoice::CEUTA_POSTAL_CODE or first_two_digits == Invoice::MELILLA_POSTAL_CODE or first_two_digits == Invoice::LAS_PALMAS_POSTAL_CODE or first_two_digits == Invoice::TENERIFE_POSTAL_CODE
        return true
      else
        return false
      end
    end


  end


  # Check for IVA
  def vat_valid?(iva)

    #apply_iva = false

    if iva
      iva_country = iva[0..1]
      iva_code = iva[2..iva.length]

      url = "http://isvat.appspot.com/" + iva_country.to_s + "/" + iva_code.to_s + "/"
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      if response.body == "true"
        true
        #@invoice.iva = iva
      else
        false
        #apply_iva = true
      end
    else
      false
      #apply_iva = true
    end
  end




  # GetExpressCheckoutDetails API call
  def get_details
    @token=params[:token].to_s
    @transaction = @shopping.get_ec_details(@token)

    @payerid= @transaction.response["PAYERID"].to_s
    session[:payerid] = @payerid
    @transaction = @shopping.get_ec_details(@token, @payerid)

    if @transaction.success?
      session[:ecdetails]=@transaction.response
      redirect_to :action => 'show_details'
    else
      session[:paypal_error]=@transaction.response
      redirect_to :action => 'error'
    end
    rescue Errno::ENOENT => exception
    flash[:error] = exception
    redirect_to :action => 'exception'

  end

  def show_details
    @response = session[:ecdetails]
  end

  def create_recurring
    token    = session[:token]
    payerid  = session[:payerid]

    i = 0
    # It creates a payment for every type of license purchased by the user.
    @shopping.incomplete_monthly_licences.each { |s|
      if @shopping.apply_iva?
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:monthly]] * 1.18
      else
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:monthly]]
      end
      @transaction = @shopping.create_recurring(token, payerid, s, ammount, i)
      i+=1
      break if !@transaction.success? # Warning! Something failed
    }

    @shopping.incomplete_biannual_licences.each { |s|
      if @shopping.apply_iva?
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:biannual]] * 1.18
      else
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:biannual]]
      end
      #s.update_status(Subscription::STATUS[:Waiting])
      @transaction = @shopping.create_recurring(token, payerid, s, ammount, i)
      i+=1
      break if !@transaction.success? # Warning! Something failed
    }

    @shopping.incomplete_annual_licences.each { |s|
      if @shopping.apply_iva?
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:annual]] * 1.18
      else
        ammount = Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:annual]]
      end
      @transaction = @shopping.create_recurring(token, payerid, s, ammount, i)
      i+=1
      break if !@transaction.success? # Warning! Something failed
    }

    if @shopping.incomplete_videoconference_subscription
      if @shopping.apply_iva?
        ammount = VideoconferenceSubscription::AMMOUNT * 1.18
      else
        ammount = VideoconferenceSubscription::AMMOUNT
      end
      @transaction = @shopping.create_recurring(token, payerid, @shopping.incomplete_videoconference_subscription, ammount, i, true)
      i+=1
      break if !@transaction.success? # Warning! Something failed
    end

    session[:token] = nil
    session[:payerid] = nil

    if @transaction.success?
      @shopping.invoice.status = Invoice::STATUS[:Completed]
      @shopping.invoice.shopping_cart_id = ''
      @shopping.invoice.save
      session[:create_recurring]=@transaction.response
      redirect_to :action => 'thanks'
    else
      session[:paypal_error]=@transaction.response
      redirect_to :action => 'error'
    end
    rescue Errno::ENOENT => exception
      flash[:error] = exception
      redirect_to :action => 'exception'
  end

  def thanks
    @shopping.clear_subscriptions

    @response = session[:create_recurring]
  end

  def error
    @response = session[:paypal_error]
  end

  def exception
    #TODO
  end


  private

  def load_shopping_cart
    @shopping = ShoppingCart.find_by_id(params[:id]) || current_user.shopping_cart

    if !@shopping
      @shopping = current_user.build_shopping_cart
      @shopping.save
    end
  end


  def create_incomplete_subscription(mode)

    if (current_user.subscription && current_user.has_paid_license?) || (current_user.subscription && current_user.subscription.incomplete?)
      subscription = current_user.sponsor_subscriptions.build
      subscription.licence_type = mode
      subscription.status = Subscription::STATUS[:Incomplete]
      subscription.shopping_cart = @shopping
      subscription.save
    else
      subscription = current_user.build_subscription
      subscription.licence_type = mode
      subscription.status = Subscription::STATUS[:Incomplete]
      subscription.shopping_cart = @shopping
      subscription.save
    end

  end

  def create_incomplete_videoconference_subscription
    videoconference = current_user.videoconference_subscriptions.new
    videoconference.status = VideoconferenceSubscription::STATUS[:Incomplete]
    videoconference.shopping_cart = @shopping
    videoconference.save

  end

end
