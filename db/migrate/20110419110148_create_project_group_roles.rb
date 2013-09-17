class CreateProjectGroupRoles < ActiveRecord::Migration
  def self.up
    create_table :project_group_roles do |t|
      t.references :user
      t.references :project_group
      t.integer :role, :default => 20

      t.timestamps
    end
  end

  def self.down
    drop_table :project_group_roles
  end
end
