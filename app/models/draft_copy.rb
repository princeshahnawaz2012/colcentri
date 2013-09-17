class DraftCopy < ActiveRecord::Base

belongs_to :message
belongs_to :draft_recipient, :class_name => "User"
delegate :created_at, :subject, :user, :body, :draft_recipients, :to=> :message


end