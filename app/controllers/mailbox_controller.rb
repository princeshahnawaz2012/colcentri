class MailboxController < ApplicationController
  skip_before_filter :load_project

  def index
    @messages = current_user.received_messages.paginate :per_page => 10, :page => params[:page], :include => :message, :order => "messages.created_at DESC"
    render '/shared/_mailbox_messages'
  end

  def delete_received
    @message =  MessageCopy.find(params[:id])
    @message.deleted=true
    if @message.save
      redirect_to :action => 'index'
    end
  end

  def delete_sent_saved
    @message =  Message.find(params[:id])
    @message.deleted=true
    if @message.save
      if @message.sent?
      redirect_to :controller => 'sent', :action => 'index'
      else
      redirect_to :controller => 'drafts', :action => 'index'
      end
    end
  end



  def message_actions

    if params[:message]
        @original = Message.find(params[:id])
        @body = params[:message][:body]
    end
    if params[:message_copy]
        @original_copy = MessageCopy.find(params[:id])
        @original = Message.find(@original_copy.message_id)
        @body = params[:message_copy][:body]
    end

    if params[:draft_copy]
          @original = DraftCopy.find(params[:id])
          @body = params[:draft_copy][:body]
    end

    @subject = @original.subject.sub(/^(Re: )?/, "Re: ")
    @recipients_ids = @original.recipients.map(&:id)

      if @original.conv_id == nil   #received message is not from a conversation
    @original.conv_id = @original.id #then the conv identifier is the id of the first message
    @conv = @original.id #the conv_id used from now
    else
    @conv = @original.conv_id
    end


    if @original.save
      with_action do |a|
        a.reply_all {reply_all}
        a.save_draft {save_draft}
        a.send_draft {send_draft}
        a.update_draft {update_draft}
        a.update_conv_draft {update_conv_draft}

      end
    end

  end


  def reply_all
    @reply = current_user.sent_messages.build(:subject => @subject, :body => @body)

    @recipients_ids.each do |recipient_id|
       @reply.message_copies.build(:recipient_id => recipient_id, :message => @reply, :read => false)
    end

    @reply.conv_id = @conv

       if @reply.save
         flash[:notice] = t('mail.mailbox.reply_sent')
         redirect_to show_sent_path
    end
  end

  def save_draft
    @draft = current_user.drafts.build(:subject => @subject, :body => @body)

    @recipients_ids.each do |recipient_id|
      @draft.draft_copies.build(:message_id => self.id, :draft_recipient_id => recipient_id)
    end

    @draft.conv_id = @conv

    if @draft.save
      flash[:notice] = t('mail.mailbox.reply_saved')
      redirect_to show_inbox_path
    end
  end

  def update_conv_draft
    @draft = current_user.drafts.find(params[:id])
    @draft.update_attributes(:body => params[:message][:body])

    if @draft.save
      flash[:notice] = t('mail.mailbox.draft_saved')
      redirect_to show_drafts_path
    end
  end

  def update_draft
    if params[:message][:draft_recipients]
      new_draft_recipients = params[:message][:draft_recipients].split(/, */)
      new_draft_recipients.each_with_index do |login,index|
       new_draft_recipients[index] = User.find_by_login(login)
      end

    end


    @draft = current_user.drafts.find(params[:id])
    old_draft_recipients = @draft.draft_recipients

    @draft.update_attributes(:body => params[:message][:body], :subject => params[:message][:subject])

    if params[:message][:draft_recipients]
      old_draft_recipients.each do |old_recipient|
        DraftCopy.delete_all(["message_id = ? AND draft_recipient_id = ?", @draft.id, old_recipient.id])
    end

      new_draft_recipients.each do |recipient|
        unless recipient.nil?
          @draft.draft_copies.build(:message_id => self.id, :draft_recipient =>  recipient)
        end
      end
    end

    if @draft.save
      flash[:notice] = t('mail.mailbox.draft_saved')
      redirect_to :controller => 'drafts', :action => 'index'
    end

  end

  def send_draft
    @draft = current_user.drafts.find(params[:id])
    old_draft_recipients = @draft.draft_recipients

    @draft.update_attributes(:body => params[:message][:body], :sent => true)

    if params[:message][:draft_recipients] #si actualizamos los destinatarios

      new_draft_recipients = params[:message][:draft_recipients].split(/ , */) # recuperar los destinatarios separados por coma

      new_draft_recipients.each do |recipient| #crear copias para cada nuevo destinatario
        recipient_id = User.find_by_login(recipient).id
        @draft.message_copies.build(:recipient_id => recipient_id, :read => false)
      end

      else

      old_draft_recipients.each do |recipient| # si no, crear copias para cada destinatario
        @draft.message_copies.build(:recipient => recipient, :read => false)
      end

    end

    old_draft_recipients.each do |old_recipient| #eliminar las entradas de la tabla draft_copies
      DraftCopy.delete_all(["message_id = ? AND draft_recipient_id = ?", @draft.id, old_recipient.id])
    end

    if @draft.save
      flash[:notice] = t('mail.mailbox.draft_sent')
      redirect_to "/sent"
    end
  end

  def mailbox_delete(message)
    message.sent = true
  end

end
