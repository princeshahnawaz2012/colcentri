module VideoconferencesHelper

  def cancel_participant_link(participant_id, video_id, login)
    link_to '', delete_participant_videoconference_path(:participant => participant_id, :id => video_id),
            :class => 'trash_icon',  :confirm => t('videoconferences.feedback.confirm_delete', :name => login)
  end

end
