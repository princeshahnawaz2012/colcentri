class AddUsedStorageToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :used_storage, :integer, :default => 0
  end

  def self.down
    remove_column :users, :used_storage
  end
end