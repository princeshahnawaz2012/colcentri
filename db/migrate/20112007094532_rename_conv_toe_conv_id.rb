class RenameConvToeConvId < ActiveRecord::Migration
  def self.up
    rename_column :message_copies, :conv, :conv_id
  end

  def self.down
    rename_column :message_copies, :conv_id, :conv
  end
end
