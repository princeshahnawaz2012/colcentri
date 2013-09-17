class AddPrivateToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :private, :boolean
  end

  def self.down
    remove_column :tasks, :private
  end
end
