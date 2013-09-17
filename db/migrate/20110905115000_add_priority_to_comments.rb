class AddPriorityToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :priority, :integer
    add_column :comments, :previous_priority, :integer
  end

  def self.down
    remove_column :comments, :priority
    remove_column :comments, :previous_priority
  end
end