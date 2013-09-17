require 'cgi'
require 'caller'

config_paypal ||= YAML.load_file("./config/paypal.yml")
Colcentric::Application.config.paypal = config_paypal
