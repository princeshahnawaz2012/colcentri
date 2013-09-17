class AddVatToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :vat, :string
  end

  def self.down
    remove_column :subscriptions, :vat
  end
end
