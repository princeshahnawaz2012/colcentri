class AddCompanyMembersToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :company_members, :integer
  end

  def self.down
    remove_column :users, :company_members
  end
end
