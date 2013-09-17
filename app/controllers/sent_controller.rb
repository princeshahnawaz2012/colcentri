  class SentController < ApplicationController

  skip_before_filter :load_project
  require 'with_action'

  def index
   @messages = current_user.sent_messages.paginate :per_page => 10,   :page => params[:page], :order => "created_at DESC"
   render '/shared/_mailbox_messages'
  end

  def show
   @message = current_user.sent_messages.find(params[:id]) # the message selected in the mailbox

   unless @message.conv_id.nil?
     @messages = Message.where(:conv_id => @message.conv_id)
   else
     @messages=@message.to_a
   end
   render '/shared/_show_message'
  end

  def create
    with_action do |a|
      a.save_draft {save_draft}
      a.do_send {do_send}
    end
  end

  def do_send
    @message = current_user.sent_messages.build(params[:message])
    @recipients = @message.to.split(/, */)
    not_found_recipients = []

    @recipients.each do |recipient_login|
      @recipient = User.find_by_login(recipient_login)
      unless @recipient.nil?
        @message.message_copies.build(:recipient_id => @recipient.id, :read => false)
      else
        not_found_recipients << recipient_login
      end
    end

    if not_found_recipients.empty?
      if @message.save
        flash[:notice] = t('mail.mailbox.message_sent')
        redirect_to :controller => 'sent', :action => 'index'
      end
    else
      flash[:error] = t('errors.private_messages.recipient_not_found', :users=> not_found_recipients.to_sentence)
      render :action => 'new'
    end


  end

  def save_draft
    @draft = current_user.drafts.build(params[:message])
    @recipients = @draft.to.split(/, */)

    @recipients.each do |recipient_login|
      @recipient = User.find_by_login(recipient_login)
      unless @recipient.nil?
        @draft.draft_copies.build(:message_id => self.id, :draft_recipient => @recipient)
      end
    end

    if @draft.save
      flash[:notice] = t('mail.mailbox.draft_saved')
      redirect_to :controller => 'drafts', :action => 'index'
    end
  end

end
