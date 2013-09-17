class DropVideoconferences < ActiveRecord::Migration

  def self.up
    drop_table :videoconferences
  end

  def self.down
    create_table :videoconferences do |t|
      t.references :user
      t.string :video_number
      t.string :topic
      t.integer :duration
      t.timestamp :start_time
      t.string :timezone
      t.string :friendly_url
      t.string :password
      t.timestamps
    end

  end

end
