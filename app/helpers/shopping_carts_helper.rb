module ShoppingCartsHelper

  def jsBuyFormValidation
    javascript_tag <<-EOS
      function validate(form) {
        var res = true;

        var invoice_type = form.shopping_cart_invoice_invoice_type;
        var first_name = form.shopping_cart_invoice_first_name;
        var last_name = form.shopping_cart_invoice_last_name;
        var company = form.shopping_cart_invoice_organization;
        var phone = form.shopping_cart_invoice_phone;
        var email = form.shopping_cart_invoice_email;
        var country = form.shopping_cart_invoice_country;
        var address = form.shopping_cart_invoice_address;
        var city = form.shopping_cart_invoice_city;
        var postal_code = form.shopping_cart_invoice_postal_code;
        var monthly_quantity = form.shopping_cart_monthly_licences_quantity.value;
        var biannual_quantity = form.shopping_cart_biannual_licences_quantity.value;
        var annual_quantity = form.shopping_cart_annual_licences_quantity.value;
        var videoconference_quantity = form.shopping_cart_videoconference_quantity.value;

        if ((monthly_quantity + biannual_quantity + annual_quantity + videoconference_quantity) == "0000"){
          res=false;
          Element.show('no_subscription_error');
          }else{
          Element.hide('no_subscription_error');
          }

//total quantity<10
        if (parseInt(monthly_quantity)+parseInt(biannual_quantity)+parseInt(annual_quantity)+parseInt(videoconference_quantity) > 10){
        res=false;
        Element.show('too_many_subscriptions_error')
        }

//can user purchase  videoconferences

        if (invoice_type.value == 1){

          if (first_name.value.length == 0){
            res = false;
            Element.show('first_name_error');
            form.shopping_cart_invoice_first_name.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('first_name_error');
          }

          if(last_name.value.length == 0){
            res = false;
            Element.show('last_name_error');
            form.shopping_cart_invoice_last_name.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('last_name_error');
          }


          if(company.value.length == 0){
            res = false;
            Element.show('company_error');
            form.shopping_cart_invoice_organization.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('company_error');
          }


          if(!email.value.match(/^[\\w\\.%\\-]+@(?:[A-Z0-9\\-]+\\.)+(?:[A-Z]{2,3}|com|org|net|es|fr|edu|gov|mil|biz|info|mobi|name|aero|jobs|coop|museum)$/i)) {
            res = false;
            Element.show('email_error');
            form.shopping_cart_invoice_email.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('email_error');
          }


          if(country.value.length == 0){
            res = false;
            Element.show('country_error');
            form.shopping_cart_invoice_country.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('country_error');
          }


          if(address.value.length == 0){
            res = false;
            Element.show('address_error');
            form.shopping_cart_invoice_address.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('address_error');
          }


          if(city.value.length == 0){
            res = false;
            Element.show('city_error');
            form.shopping_cart_invoice_city.up(1).setAttribute("class", "field_with_errors");
          }else{
             Element.hide('city_error');
          }


          if(postal_code.value.length == 0){
            res = false;
            Element.show('postal_code_error');
            form.shopping_cart_invoice_postal_code.up(1).setAttribute("class", "field_with_errors");
          }else{
            Element.hide('postal_code_error');
          }

        }

        return res;
      }


    EOS
  end


  def jsBuyFormUpdateTotal
    javascript_tag <<-EOS
      function updateTotal(form) {

        var total_amount = 0.0;
        var sub_total = 0.0;

        var monthly_price = #{Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:monthly]]};
        var biannual_price = #{Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:biannual]]};
        var annual_price = #{Subscription::LICENCE_TYPE_AMOUNT[Subscription::LICENCE_TYPE[:annual]]};
        var videoconference_price = #{VideoconferenceSubscription::AMMOUNT};

        var monthly_quantity = form.shopping_cart_monthly_licences_quantity.value;
        var biannual_quantity = form.shopping_cart_biannual_licences_quantity.value;
        var annual_quantity = form.shopping_cart_annual_licences_quantity.value;
        var videoconference_quantity = form.shopping_cart_videoconference_quantity.value;

        if (monthly_quantity > 0){
          sub_total = monthly_quantity * monthly_price;
          document.getElementById("Sub_total_monthly").innerHTML = (sub_total.toFixed(2)).toString().concat(" €");
          total_amount += sub_total;
        }else{
          document.getElementById("Sub_total_monthly").innerHTML = "0.00 €"
        }

        if(biannual_quantity > 0){
          sub_total = biannual_quantity * biannual_price;
          document.getElementById("Sub_total_biannual").innerHTML = (sub_total.toFixed(2)).toString().concat(" €");
          total_amount += sub_total;
        }else{
          document.getElementById("Sub_total_biannual").innerHTML = "0.00 €"
        }


        if(annual_quantity > 0){
          sub_total = annual_quantity * annual_price;
          document.getElementById("Sub_total_annual").innerHTML = (sub_total.toFixed(2)).toString().concat(" €");
          total_amount += sub_total;
        }else{
          document.getElementById("Sub_total_annual").innerHTML = "0.00 €"
        }


        if(videoconference_quantity > 0){
          sub_total = videoconference_quantity * videoconference_price;
          document.getElementById("Sub_total_videoconference").innerHTML = (sub_total.toFixed(2)).toString().concat(" €");
          total_amount += sub_total;
        }else{
          document.getElementById("Sub_total_videoconference").innerHTML = "0.00 €"
        }

        document.getElementById("total_amount").innerHTML = (total_amount.toFixed(2)).toString().concat(" €");


      }

      EOS



  end


  def license_amount_to_pay(licence, quantity)
    t("subscriptions.fields.total.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}", :amount => Subscription::LICENCE_TYPE_AMOUNT[licence] * Integer(quantity)) if licence
  end


  def js_for_buy_form_validations
    error_messages =
      %w(too_long too_short empty invalid confirmation terms_of_use).inject({}) do |r,key|
        r[key] = t("activerecord.errors.messages.#{key}")
        r
      end
    strength_messages =
      %w(too_short weak average strong too_long).inject({}) do |r,key|
        r[key] = t("password_strength.#{key}")
        r
      end

    javascript_tag <<-EOS
    var FieldMessages = (#{error_messages.to_json})
    var StrengthMessages = (#{strength_messages.to_json})
    var FieldErrors = {
      add: function(input, message) {
        input.up('div').addClassName('field_with_errors')
        input.up('.text_field').down('.errors_for').innerHTML = message
        this.setSuccess(input, false)
      },
      clear: function(input) {
        if (input.up('.field_with_errors'))
          input.up('.field_with_errors').removeClassName('field_with_errors')
        input.up('.text_field').down('.errors_for').innerHTML = ""
        this.setSuccess(input, true)
      },
      setSuccess: function(input, status) {
        var icon = input.up('.text_field').down('.result_icon')
        if (!icon) {
          var icon = new Element('div', { 'class': 'result_icon' })
          input.insert({after: icon})
        }
        icon.className = 'result_icon ' + (status ? 'static_tick_icon' : 'static_cross_icon')
      }
    }

    document.on('change', '#shopping_cart_invoice_first_name, #shopping_cart_invoice_last_name, #shopping_cart_invoice_phone, #shopping_cart_invoice_organization, #shopping_cart_invoice_country', function(e,input) {
      if(input.value.length > 20) {
        FieldErrors.add(input, FieldMessages.too_long.gsub('%{count}',20))
      } else if (input.value.length < 1) {
        FieldErrors.add(input, FieldMessages.empty)
      } else {
        FieldErrors.clear(input)
      }
    })

    document.on('change', '#shopping_cart_invoice_email', function(e,input) {
      if(!input.value.match(/^[\\w\\.%\\-]+@(?:[A-Z0-9\\-]+\\.)+(?:[A-Z]{2,3}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|jobs|coop|museum)$/i)) {
        FieldErrors.add(input, FieldMessages.invalid)
      } else if (input.value.length > 100) {
        FieldErrors.add(input, FieldMessages.too_long.gsub('%{count}',100))
      } else {
        FieldErrors.clear(input)
      }
    })

    document.on('change', '#shopping_cart_invoice_phone', function(e, input){
       // TO DO --> Only accepts numbers.
      if(!input.value.match(/^[0-9_]+$/i)) {
        FieldErrors.add(input, FieldMessages.invalid)
      } else{
        FieldErrors.clear(input)
      }
    })

    EOS
  end




end
