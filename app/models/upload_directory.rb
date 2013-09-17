class UploadDirectory < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  belongs_to :upload_directory

  has_many :uploads

  attr_accessible :id, :name, :project_id, :user_id, :upload_directory_id, :size, :created_at, :updated_at
end
