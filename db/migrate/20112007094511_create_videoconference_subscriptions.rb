class CreateVideoconferenceSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :videoconference_subscriptions do |t|
      t.integer :status
      t.references :user
      t.references :shopping_cart
      t.string :paypal_profileid
      t.string :paypal_profilestatus
      t.string :paypal_correlationid
      t.datetime :last_payment_date
      t.datetime :expiration_date
      t.timestamps
    end
  end

  def self.down
    drop_table :videoconference_subscriptions
  end
end
