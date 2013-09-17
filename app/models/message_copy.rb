class MessageCopy < ActiveRecord::Base
  after_initialize :default_values

  belongs_to :message
  belongs_to :recipient, :class_name => "User"
  delegate  :created_at, :subject, :user, :body, :recipients, :sent, :to=> :message

  def sent?
    self.sent
  end

  def deleted?
    self.deleted
  end

  private
  def default_values
    self.deleted = false
    self.read = false
  end

end
