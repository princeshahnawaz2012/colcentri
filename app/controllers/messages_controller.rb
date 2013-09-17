class MessagesController < ApplicationController
  require 'with_action'

  skip_before_filter :load_project


  def new
    @message = current_user.sent_messages.build
    render :action => "new"
  end


  def show
    @message = current_user.received_messages.find(params[:id])
    @conversation = Message.find(@message.message_id).conv_id
    @original =  Message.find(@message.message_id)

    unless @conversation.nil?
      @messages = Message.find_all_by_conv_id(@conversation)
    else
      @messages = @original.to_a
    end

    @message.read = true
    @message.save

    render '/shared/_show_message'
  end


end

