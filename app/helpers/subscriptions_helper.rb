module SubscriptionsHelper
  def options_from_licence_types
    Subscription::LICENCE_TYPE.map { |licence, value|
      [t("subscriptions.fields.#{licence}"), value] if value > 3
    }.compact.sort_by(&:last)
  end

  def licence_type_name_without_price(licence)
    t("subscriptions.fields_without_price.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}") if licence
  end

  def licence_type_name(licence)
    t("subscriptions.fields.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}") if licence
  end

  def subscription_type_name(licence)
    t("subscriptions.types.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}") if licence
  end

  def licence_duration_name(licence)
    t("subscriptions.fields.duration.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}") if licence
  end

  def licence_cost_name(licence)
    t("subscriptions.fields.cost.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}") if licence
  end

  def subscription_amount_to_pay(licence, quantity)
    amount = Subscription::LICENCE_TYPE_AMOUNT[licence] * Integer(quantity)

    t("subscriptions.fields.total.#{Subscription::LICENCE_TYPE.find{ |key, value| value == licence}.first}", :amount => amount) if licence
  end

  def subscription_status_name(status)
    t("subscriptions.status.#{Subscription::STATUS.find{ |key, value| value == status}.first}")
  end

  def cancel_subscription_link(subscription)
    link_to content_tag(:span,t('subscriptions.delete.forever')),
    cancel_subscription_path(subscription),
    :class => 'text_button',
    :confirm => t('subscriptions.delete.confirm_delete')
  end

  def assign_subscription_link(licence)
    link_to_function t('.assign'), show_invitation_fields(licence), :class => 'text_button'
  end

  def show_invitation_fields(licence)
    if licence == Subscription::LICENCE_TYPE[:monthly]
      update_page do |page|
        @section = "monthly_form"
        #page['monthly_invitations_fields'].reload
        page['special_invitations_fields'].hide
        page['annual_invitations_fields'].hide
        page['halfyear_invitations_fields'].hide
        page['monthly_invitations_fields'].show
        page['monthly_invitation_field'].focus
        page['monthly_invitations_fields'].scrollIntoView

      end
    elsif licence == Subscription::LICENCE_TYPE[:biannual]
      update_page do |page|
        page['special_invitations_fields'].hide
        page['annual_invitations_fields'].hide
        page['monthly_invitations_fields'].hide
        page['halfyear_invitations_fields'].show
        page['halfyear_invitation_field'].focus
        page['halfyear_invitations_fields'].scrollIntoView
      end
    elsif licence == Subscription::LICENCE_TYPE[:annual]
      update_page do |page|
        page['special_invitations_fields'].hide
        page['halfyear_invitations_fields'].hide
        page['monthly_invitations_fields'].hide
        page['annual_invitations_fields'].show
        page['annual_invitation_field'].focus
        page['annual_invitations_fields'].scrollIntoView
      end
    elsif licence == Subscription::LICENCE_TYPE[:special]
      update_page do |page|
        page['annual_invitations_fields'].hide
        page['halfyear_invitations_fields'].hide
        page['monthly_invitations_fields'].hide
        page['special_invitations_fields'].show
        page['special_invitation_field'].focus
        page['special_invitations_fields'].scrollIntoView
      end
    end
  end
end
