class AddOrganizationIdToProjectGroups < ActiveRecord::Migration
  def self.up
    add_column :project_groups, :organization_id, :integer
  end

  def self.down
    remove_column :project_groups, :organization_id
  end
end
