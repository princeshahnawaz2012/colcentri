class CreatePrivateMessages < ActiveRecord::Migration
  def self.up
    create_table :private_messages do |t|
      t.references :user
      t.integer :recipient
      t.time :time
      t.date :date
      t.string :subject
      t.boolean :read
      t.text :content

      t.timestamps
    end
  end

  def self.down
    drop_table :private_messages
  end
end
