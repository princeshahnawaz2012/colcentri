class CreateParticipants < ActiveRecord::Migration
  def self.up
    create_table :participants do |t|
      t.references :videoconference
      t.integer :type
      t.string :login_or_email
      t.boolean :invitation_email
      t.timestamps
    end
  end

  def self.down
    drop_table :participants
  end
end

