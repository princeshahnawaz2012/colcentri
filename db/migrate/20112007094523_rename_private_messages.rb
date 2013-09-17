class RenamePrivateMessages < ActiveRecord::Migration
  def self.up
    rename_table :private_messages, :messages
  end

  def self.down
    rename_table :messages, :private_messages
  end
end
