class AddStartDateToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :start_date, :date
  end

  def self.down
    remove_column :tasks, :start_date
  end
end
