class DropInvoices < ActiveRecord::Migration

  def self.up
    drop_table :invoices
  end

  def self.down
    create_table :invoices do |t|
      t.references :user
      t.string :invoice_number
      t.integer :status
      t.string :first_name
      t.string :last_name
      t.string :organization
      t.string :phone
      t.string :email
      t.string :country
      t.string :address
      t.string :city
      t.string :postal_code
      t.integer :n_monthly_licenses
      t.integer :n_biannual_licenses
      t.integer :n_annual_licenses
      t.integer :n_videoconferences
      t.integer :n_storage
      t.float :ammount
      t.timestamps
    end
  end

end