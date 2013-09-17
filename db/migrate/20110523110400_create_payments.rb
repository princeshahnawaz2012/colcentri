class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :status
      t.integer :payment_mode
      t.references :user
      t.references :sponsor_user
      t.string :paypal_profileid
      t.string :paypal_profilestatus
      t.string :paypal_correlationid
      t.datetime :last_payment_date
      t.datetime :expiration_date
      t.boolean :deleted

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
