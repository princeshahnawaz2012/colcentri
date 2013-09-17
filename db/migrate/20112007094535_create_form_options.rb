class CreateFormOptions < ActiveRecord::Migration
  def self.up
    create_table :form_options do |t|
      t.references :field
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :form_options
  end
end
