class RenamePaymentsToSubscriptions < ActiveRecord::Migration
  def self.up
    rename_table :payments, :subscriptions
  end

  def self.down
    rename_table :subscriptions, :payments
  end
end
