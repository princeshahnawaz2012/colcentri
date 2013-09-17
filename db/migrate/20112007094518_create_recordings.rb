class CreateRecordings < ActiveRecord::Migration
  def self.up
    create_table :recordings do |t|
      t.references :videoconference
      t.string :room_id
      t.string :record_id
      t.boolean :anonymous_playback
      t.string :title
      t.string :description
      t.string :password
      t.integer :duration
      t.string :recording_link
      t.datetime :creation_date
      t.timestamps
    end
  end

  def self.down
    drop_table :recordings
  end
end
