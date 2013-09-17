class AddPaymentIdToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :payment_id, :integer
  end

  def self.down
    remove_column :invitations, :payment_id
  end
end
