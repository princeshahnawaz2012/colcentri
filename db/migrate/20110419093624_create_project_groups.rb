class CreateProjectGroups < ActiveRecord::Migration
  def self.up
    create_table :project_groups do |t|
      t.string :name
      t.string :permalink

      t.timestamps
    end
    add_column :projects, :project_group_id, :integer
  end

  def self.down
    remove_column :projects, :project_group_id
    drop_table :project_groups
  end
end
