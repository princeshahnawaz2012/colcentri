class RenameRecipientIdToDraftRecipientId < ActiveRecord::Migration
  def self.up
    rename_column :drafts, :recipient_id, :draft_recipient_id
  end

  def self.down
    rename_column :drafts,  :draft_recipient_id, :recipient_id
  end
end
