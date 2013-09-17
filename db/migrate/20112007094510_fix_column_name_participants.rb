class FixColumnNameParticipants < ActiveRecord::Migration
  def self.up
    rename_column :participants, :type, :role
  end

  def self.down
  end
end
