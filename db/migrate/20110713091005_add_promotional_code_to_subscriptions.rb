class AddPromotionalCodeToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :promotional_code, :string
  end

  def self.down
    remove_column :subscriptions, :promotional_code
  end
end
