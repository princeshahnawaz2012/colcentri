class Participant < ActiveRecord::Base
  # Invitation_email is set to 1 when an e-mail has been sent to the user.
  # So, it is not necessary to send it again.

  belongs_to :videoconference
  belongs_to :user

  #scope :moderator, :conditions => "type = #{TYPE[:moderator]}"
  #scope :participant, :conditions => "type = #{TYPE[:participant]}"
  #scope :observer, :conditions => "type = #{TYPE[:observer]}"

  attr_accessible :role, :login_or_email, :invitation_email

  ROLE = { :moderator => 1, :participant => 2, :observer => 3 }

end
