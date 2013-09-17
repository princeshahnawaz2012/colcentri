class AddTermsOfUseToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :terms_of_use, :boolean
  end

  def self.down
    remove_column :users, :terms_of_use
  end
end
