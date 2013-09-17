class AddConvToMessageCopies < ActiveRecord::Migration
  def self.up
     add_column :message_copies, :conv, :integer
  end

  def self.down
     remove_column :message_copies, :conv
  end
end
