class AddParticipantsToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :participants, :string
  end

  def self.down
    remove_column :tasks, :participants
  end
end