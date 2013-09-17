class RenamePaymentToSubscription < ActiveRecord::Migration
  def self.up
    rename_column :invitations, :payment_id, :subscription_id
  end

  def self.down
    rename_column :invitations, :subscription_id, :payment_id
  end
end
