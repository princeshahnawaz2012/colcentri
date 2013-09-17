class UserDirectory < ActiveRecord::Base
  belongs_to :user
  has_many :user_files

  attr_accessible :id, :name

  validates_presence_of :name, :user_id

end
