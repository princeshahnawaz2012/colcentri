class AddOwnerToProjectGroup < ActiveRecord::Migration
  def self.up
    add_column :project_groups, :user_id, :integer
  end

  def self.down
    remove_column :project_groups, :user_id
  end
end
