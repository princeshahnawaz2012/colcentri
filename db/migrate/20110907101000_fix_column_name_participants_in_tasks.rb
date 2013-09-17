class FixColumnNameParticipantsInTasks < ActiveRecord::Migration
  def self.up
     rename_column :tasks, :participants, :task_participants
  end

  def self.down
  end
end
