class AddSentToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :sent, :boolean
  end

  def self.down
    remove_column :messages, :sent, :boolean
  end
end
