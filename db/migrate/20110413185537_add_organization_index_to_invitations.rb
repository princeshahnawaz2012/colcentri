class AddOrganizationIndexToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :organization_id, :integer
    add_index :invitations, [:organization_id]
  end

  def self.down
    remove_index :invitations, :column => [:organization_id]
    remove_column :invitations, :organization_id
  end
end
