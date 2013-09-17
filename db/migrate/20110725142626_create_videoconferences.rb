class CreateVideoconferences < ActiveRecord::Migration
  def self.up
    create_table :videoconferences do |t|
      t.references :user
      t.string :room_number
      t.integer :room_id
      t.string :topic
      t.integer :duration
      t.timestamp :start_time
      t.string :timezone
      t.string :friendly_url
      t.string :password
      t.timestamps
    end
  end

  def self.down
    drop_table :videoconferences
  end
end
