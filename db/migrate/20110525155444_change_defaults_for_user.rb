class ChangeDefaultsForUser < ActiveRecord::Migration
  def self.up
    change_column :users, :wants_task_reminder, :boolean, :default => false
  end

  def self.down
    change_column :users, :wants_task_reminder, :boolean, :default => true
  end
end
