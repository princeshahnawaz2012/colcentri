class CreateFields < ActiveRecord::Migration
  def self.up
    create_table :fields do |t|
      t.references :form
      t.string :name
      t.integer :field_type
      t.timestamps
    end
  end

  def self.down
    drop_table :fields
  end
end
