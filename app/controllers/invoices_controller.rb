class InvoicesController < ApplicationController

  skip_before_filter :load_project



  def index
    current_user.clear_invoices
    @name = current_user.login
    @invoices = current_user.invoices.where(:status => 0)
  end

  def show
    @invoice = Invoice.find(params[:id])
  end

end
