class RemoveNumberOfEmployees < ActiveRecord::Migration
  def self.up
    remove_column :users, :company_members
  end

  def self.down
    add_column :users, :company_members, :integer
  end
end
