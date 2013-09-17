module ConversationsHelper

  def jsForConversationValidation
     javascript_tag <<-EOS

      function validate_conversation(form){
      var first_comment = form.conversation_comments_attributes_0_body
      var res = true;

      if(first_comment.value.length < 1){
      Element.show(no_description_error);
      first_comment.up(0).setAttribute("class", "field_with_errors");
      var res=false;
      }
      return res;
    }
    EOS
  end


  def conversations_primer(project)
    if project.editable?(current_user)
      render 'conversations/primer', :project => project
    end
  end
  
  def new_conversation_link(project)
    link_to image_tag(t('buttons.create_conversation')), new_project_conversation_path(project)
  end
    
  def the_conversation_link(conversation)
    link_to h(conversation.name), project_conversation_path(conversation.project,conversation), :class => 'conversation_link'
  end
  
  def conversation_comment(conversation)
    if comment = conversation.comments.first
      render 'comments/comment', :comment => comment
    end
  end
  
  def conversation_comments_count(conversation)
    pluralize(conversation.comments.size, t('.message'), t('.messages'))
  end
  
  def conversation_column(project,conversations,options={})
    options[:conversation] ||= nil
    options[:show_conversation_settings] ||= false
    
    render 'conversations/column',
      :project => project,
      :conversations => conversations,
      :conversation => options[:conversation],
      :show_conversation_settings =>  options[:show_conversation_settings]
  end

end