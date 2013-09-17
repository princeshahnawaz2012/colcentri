class CreateDrafts < ActiveRecord::Migration
  def self.up
    create_table :drafts do |t|
      t.integer :recipient_id
      t.integer :message_id

      t.timestamps
    end
  end

  def self.down
    drop_table :drafts
  end
end
