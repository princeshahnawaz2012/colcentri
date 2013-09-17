# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a 
# newer version of cucumber-rails. Consider adding your own code to a new file 
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

ENV["RAILS_ENV"] ||= "cucumber"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')

require 'cucumber/formatter/unicode' # Remove this line if you don't want Cucumber Unicode support
require 'cucumber/rails/rspec'
require 'cucumber/rails/world'
require 'cucumber/web/tableish'

require 'capybara/rails'
require 'capybara/cucumber'
require 'capybara/session'
require 'cucumber/rails/active_record'
require 'cucumber/rspec/doubles'

require 'email_spec/cucumber'

#require 'cucumber/rails/capybara_javascript_emulation' # Lets you click links with onclick javascript handlers without using @culerity or @javascript
# Capybara defaults to XPath selectors rather than Webrat's default of CSS3. In
# order to ease the transition to Capybara we set the default here. If you'd
# prefer to use XPath just remove this line and adjust any selectors in your
# steps to use the XPath syntax.
Capybara.default_selector = :css

# If you set this to false, any error raised from within your app will bubble 
# up to your step definition and out to cucumber unless you catch it somewhere
# on the way. You can make Rails rescue errors and render error pages on a
# per-scenario basis by tagging a scenario or feature with the @allow-rescue tag.
#
# If you set this to true, Rails will rescue all errors and render error
# pages, more or less in the same way your application would behave in the
# default production environment. It's not recommended to do this for all
# of your scenarios, as this makes it hard to discover errors in your application.
ActionController::Base.allow_rescue = false

Cucumber::Rails::World.use_transactional_fixtures = true

#Capybara.register_driver :selenium do |app|
  #Capybara::Driver::Selenium
  ##profile = Selenium::WebDriver::Firefox::Profile.new
  ##profile.add_extension(File.expand_path("features/support/firebug-1.7X.0a7.xpi"))

  #Capybara::Driver::Selenium.new(app, { :browser => :firefox, :profile => "selenium" })
#end

# How to clean your database when transactions are turned off. See
# http://github.com/bmabey/database_cleaner for more info.
if defined?(ActiveRecord::Base)
  require 'database_cleaner'
  DatabaseCleaner.strategy = :truncation
end

require 'rack/test'	
require 'rack/test/cookie_jar'

Before do
  # Tests are written to target non-community version, except where noted (I am using the community version)
  Colcentric.config.community = false
end
