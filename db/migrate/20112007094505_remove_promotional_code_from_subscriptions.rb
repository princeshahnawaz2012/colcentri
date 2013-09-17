class RemovePromotionalCodeFromSubscriptions < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :promotional_code
  end

  def self.down
    add_column :subscriptions, :promotional_code, :string
  end
end
