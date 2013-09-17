class AddIvaToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :iva, :boolean, :default => false
  end

  def self.down
    remove_column :subscriptions, :iva
  end
end
