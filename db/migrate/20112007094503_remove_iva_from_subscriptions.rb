class RemoveIvaFromSubscriptions < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :iva
  end

  def self.down
    add_column :subscriptions, :iva, :boolean
  end
end
