class AddAmazonIdToUploads < ActiveRecord::Migration
  def self.up
    add_column :uploads, :amazon_id, :integer
  end

  def self.down
    remove_column :uploads, :amazon_id
  end
end