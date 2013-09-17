class AddTrialExpirationDateToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :trial_expiration_date, :datetime
  end

  def self.down
    remove_column :payments, :trial_expiration_date
  end
end
