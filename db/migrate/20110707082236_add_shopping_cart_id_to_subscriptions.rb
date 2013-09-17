class AddShoppingCartIdToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :shopping_cart_id, :integer
  end

  def self.down
    remove_column :subscriptions, :shopping_cart_id
  end
end
