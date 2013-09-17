class Message < ActiveRecord::Base
  after_initialize :default_values
  after_create :log_create

  belongs_to :user
  has_many :recipients, :through => :message_copies
  has_many :draft_recipients, :through => :draft_copies
  has_many :message_copies
  has_many :draft_copies
  belongs_to :conv
  attr_accessor :to #array  of people to send to
  attr_accessible  :subject,
                   :body,
                   :to,
                   :recipients,
                   :author,
                   :user_id,
                   :sent

  def message
    self
  end

  def log_create
    #(project,target,action,creator_id)
    Activity.log(nil, self, 'create', user_id)
  end

  private
  def default_values
    self.deleted = false
  end

end







