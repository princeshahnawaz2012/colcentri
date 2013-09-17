class RenameDraftToDraftCopy < ActiveRecord::Migration
  def self.up
    rename_table :drafts, :draft_copies
  end

  def self.down
    rename_table :draft_copies, :drafts
  end
end
