class RenameContentToBody < ActiveRecord::Migration
  def self.up
    rename_column :messages, :content, :body
  end

  def self.down
    rename_column :messages, :body, :content
  end
end
