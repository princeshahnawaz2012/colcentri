class Deletefolder < ActiveRecord::Migration
  def self.up
    drop_table :folders
  end

  def self.down
    create_table :folders do |t|
      t.integer :user_id
      t.integer :parent_id
      t.string :name

      t.timestamps
    end
  end
end
