class HelpController < ApplicationController

  skip_before_filter :load_project
  skip_before_filter :subscription_done?
  layout 'help'

  def index

  end
end
