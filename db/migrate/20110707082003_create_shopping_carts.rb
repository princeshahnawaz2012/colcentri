class CreateShoppingCarts < ActiveRecord::Migration
  def self.up
    create_table :shopping_carts do |t|
      t.string :promotional_code
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :shopping_carts
  end
end
