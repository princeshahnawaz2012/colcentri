class RemoveVatFromSubscriptions < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :vat
  end

  def self.down
    add_column :subscriptions, :vat, :string
  end
end
