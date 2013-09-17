class CreateTaskParticipants < ActiveRecord::Migration
  def self.up
    create_table :task_participants do |t|
      t.references :task
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :task_participants
  end
end
