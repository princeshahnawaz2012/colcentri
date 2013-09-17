class AddComercialCodeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :comercial_code, :string
  end

  def self.down
    remove_column :users, :comercial_code
  end
end
