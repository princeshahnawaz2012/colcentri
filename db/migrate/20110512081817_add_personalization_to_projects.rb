class AddPersonalizationToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :personalization, :integer, :default => 0
  end

  def self.down
    remove_column :projects, :personalization
  end
end
