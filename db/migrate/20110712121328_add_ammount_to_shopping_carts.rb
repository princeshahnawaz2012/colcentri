class AddAmmountToShoppingCarts < ActiveRecord::Migration
  def self.up
    add_column :shopping_carts, :ammount, :float
  end

  def self.down
    remove_column :shopping_carts, :ammount
  end
end
