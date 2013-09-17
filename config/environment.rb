# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Colcentric::Application.initialize!


#overriding default field_error_proc that caused the labels of fields with errors to change style
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  '<span class="field_with_errors">'.html_safe << html_tag <<
'</span>'.html_safe
end