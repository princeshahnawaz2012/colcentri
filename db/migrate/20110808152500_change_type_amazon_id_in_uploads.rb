class ChangeTypeAmazonIdInUploads < ActiveRecord::Migration
  def self.up
    change_column :uploads, :amazon_id, :string
  end

  def self.down
    change_column :uploads, :amazon_id, :integer
  end

end