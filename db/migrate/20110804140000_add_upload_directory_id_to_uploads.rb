class AddUploadDirectoryIdToUploads < ActiveRecord::Migration
  def self.up
    add_column :uploads, :upload_directory_id, :integer
  end

  def self.down
    remove_column :uploads, :upload_directory_id
  end
end
