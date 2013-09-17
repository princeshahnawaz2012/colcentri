class CreateCalendarEntry < ActiveRecord::Migration
  def self.up
    create_table :calendar_entries do |t|
      t.string :title
      t.string :description
      t.datetime :start_date
      t.datetime :end_date
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :calendar_entries
  end
end