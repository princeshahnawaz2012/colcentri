class CreateForms < ActiveRecord::Migration
  def self.up
    create_table :forms do |t|
      t.references :user
      t.references :project
      t.string :title
      t.string :description
      t.boolean :multiple
      t.boolean :publish
      t.timestamps
    end
  end

  def self.down
    drop_table :forms
  end
end
