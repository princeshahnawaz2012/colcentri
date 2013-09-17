class RenamePaymentModeToLicenceType < ActiveRecord::Migration
  def self.up
    rename_column :subscriptions, :payment_mode, :licence_type
  end

  def self.down
    rename_column :subscriptions, :licence_type, :payment_mode
  end
end
