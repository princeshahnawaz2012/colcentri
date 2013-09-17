class AddStartDateToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :start_date, :date
    add_column :comments, :previous_start_date, :date
  end

  def self.down
    remove_column :comments, :start_date
  end
end
