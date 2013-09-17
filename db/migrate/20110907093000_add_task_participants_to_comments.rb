class AddTaskParticipantsToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :task_participants, :string
    add_column :comments, :previous_task_participants, :string
  end

  def self.down
    remove_column :comments, :task_participants
    remove_column :comments, :previous_task_participants
  end
end