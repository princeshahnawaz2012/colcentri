class CreateUploadDirectories < ActiveRecord::Migration

def self.up
 create_table :upload_directories do |t|
    t.string   :name
    t.integer  :project_id
    t.integer  :user_id
    t.integer  :upload_directory_id
    t.integer  :size
    t.datetime :created_at
    t.datetime :updated_at
 end
end

def self.down
  drop_table :upload_directories
end

end
