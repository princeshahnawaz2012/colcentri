class DeleteReadFromMessages < ActiveRecord::Migration
  def self.up
     remove_column :messages, :read
  end

  def self.down
    add_column :messages, :read, :boolean
  end
end
