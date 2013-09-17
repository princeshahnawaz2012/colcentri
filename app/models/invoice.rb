class Invoice < ActiveRecord::Base
  belongs_to :user
  belongs_to :shopping_cart

  validates_presence_of :first_name

  attr_accessible :invoice_number, :iva, :id, :user_id, :shopping_cart_id, :status, :first_name, :last_name,
      :organization, :phone, :email, :country, :address, :city, :postal_code, :n_monthly_licenses, :n_biannual_licenses,
      :n_annual_licenses, :n_videoconferences, :n_storage, :ammount, :created_at, :updated_at, :promotional_code

  STATUS = {:Completed => 0, :Incomplete => 1, :Failed => 2}

  TYPE = { :particular => 0, :company => 1 }

  EUROPEAN_UNION_COUNTRIES_CODES = { "AT-Austria" => "AT", "BE-Belgium" => "BE", "BG-Bulgaria" => "BG", "CY-Cyprus" => "CY", "CZ-Czech Republic" => "CZ",
                                "DE-Germany" => "DE", "DK-Denmark" => "DK", "EE-Estonia" => "EE", "EL-Greece" => "EL", "ES-Spain" => "ES",
                                 "FI-Finland" => "FI", "FR-France" => "FR", "GB-United Kingdom" => "GB", "HU-Hungary" => "HU",
                                 "IE-Ireland" => "IE", "IT-Italy" => "IT", "LT-Lithuania" => "LT", "LU-Luxembourg" => "LU", "LV-Latvia" => "LV",
                                 "MT-Malta" => "MT", "NL-The Netherlands" => "NL", "PL-Poland" => "PL", "PT-Portugal" => "PT",
                                 "RO-Romania" => "RO", "SE-Sweden" => "SE", "SL-Slovenia" => "SL", "SK-Slovakia" => "SK" }

  CEUTA_POSTAL_CODE = 51
  MELILLA_POSTAL_CODE = 52
  LAS_PALMAS_POSTAL_CODE = 35
  TENERIFE_POSTAL_CODE = 38


  FIRST_INVOICE_YEAR = "11"
  FIRST_INVOICE_NUMBER = "000200"
  STARTING_INVOICE_NUMBER = "000000"

end
