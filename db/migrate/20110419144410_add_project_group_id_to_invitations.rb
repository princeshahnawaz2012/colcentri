class AddProjectGroupIdToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :project_group_id, :integer
  end

  def self.down
    remove_column :invitations, :project_group_id
  end
end
