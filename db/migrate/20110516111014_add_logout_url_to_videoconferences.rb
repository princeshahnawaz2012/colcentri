class AddLogoutUrlToVideoconferences < ActiveRecord::Migration
  def self.up
    add_column :videoconferences, :logout_url, :string
  end

  def self.down
    remove_column :videoconferences, :logout_url
  end
end
