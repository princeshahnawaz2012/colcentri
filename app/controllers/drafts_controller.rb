class DraftsController < ApplicationController

  skip_before_filter :load_project
  require 'with_action'

  def index
    @messages = current_user.drafts.paginate :per_page => 10, :page => params[:page], :order => "created_at DESC"
    render '/shared/_mailbox_messages'
  end

  def show
    @message = current_user.drafts.find(params[:id])

    unless @message.conv_id.nil?
      @messages = Message.find_all_by_conv_id(@message.conv_id) - @message.to_a
    end

    @draft_recipients = @message.draft_recipients.split(/, */)
    render '/shared/_show_message'
  end

end