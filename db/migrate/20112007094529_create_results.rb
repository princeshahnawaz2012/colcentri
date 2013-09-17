class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.references :field
      t.references :user
      t.integer :result
      t.string :value
      t.timestamps
    end
  end

  def self.down
    drop_table :results
  end
end
