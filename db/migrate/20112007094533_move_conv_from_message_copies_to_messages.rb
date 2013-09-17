class MoveConvFromMessageCopiesToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :conv_id, :integer
    remove_column :message_copies, :conv_id
  end

  def self.down
    add_column :message_copies, :conv_id, :integer
    remove_column :messages, :conv_id
  end
end
