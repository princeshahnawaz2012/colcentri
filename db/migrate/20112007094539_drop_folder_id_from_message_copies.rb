class DropFolderIdFromMessageCopies < ActiveRecord::Migration
  def self.up
    remove_column :message_copies, :folder_id
  end

  def self.down
    add_column :message_copies, :folder_id, :integer
  end
end
