module VideoconferenceSubscriptionsHelper

  def cancel_videoconference_subscription_link(subscription)
     link_to content_tag(:span,t('subscriptions.delete.forever')),
     videoconference_subscription_path(subscription),
     :method => :delete,
     :class => 'button',
     :confirm => t('subscriptions.delete.confirm_delete')
   end

end
