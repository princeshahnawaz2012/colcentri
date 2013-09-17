module EmailerHelper

  include UploadsHelper
  include TasksHelper

  def email_global
    'font-size: 12px; color: #003869; font-family: Verdana, Arial; background-color: #ffffff;'
  end

  def email_box(target = nil)
    case target
    when Task
      case target.status
      when 0 # new
        'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
      when 2 # hold
        'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
      when 3 # resolved
        'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
      when 4 # rejected
        'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
      else # assigned and default
        'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
      end
    else
      'border-bottom: 1px #cacaca solid;; border-top: 1px #cacaca solid;'
    end + 'margin: 10px; padding: 10px'
  end

  def email_text(size)
    case size
    when :small then 'font-size: 10px; color: #003869;'
    when :normal then 'font-size: 12px; color: #003869;'
    when :big   then 'font-weight: bold; font-size: 16px; color: #003869;'
    when :big_wb   then 'font-size: 16px; color: #003869;'
    end
  end

  def email_answer_line
    Emailer::ANSWER_LINE
  end

  def answer_instructions
    render 'emailer/answer'
  end

  def dont_answer
    render 'emailer/dont_answer'
  end

  def emailer_list_comments(comments)
    #render :partial => 'emailer/comment', :collection => comments, :locals => { :unread => comments.first }
    render :partial => 'emailer/comment', :collection => comments, :locals => { :unread => comments.first }
    #render :partial => 'emailer/comment', :comment => comments.last, :locals => { :unread => comments.first }
  end

  def emailer_recent_tasks(project, user)
    recent_tasks = project.tasks.unarchived.
                    assigned_to(user).
                    sort { |a,b| (a.due_on || 1.year.ago) <=> (a.due_on || 1.year.ago)}
    render 'emailer/recent_tasks', :project => project, :recent_tasks => recent_tasks
  end

  def emailer_answer_to_this_email
    content_tag(:p,I18n.t('emailer.notify.reply')) if Colcentric.config.allow_incoming_email
  end

  def emailer_commands_for_tasks(user)
    if Colcentric.config.allow_incoming_email
      content_tag(:p,I18n.t('emailer.notify.task_commands', :username => user.login))
    end
  end

  def tasks_for_daily_reminder(tasks, user, header)
    if tasks && tasks.any?
      render 'emailer/tasks_for_daily_reminder', :tasks => tasks, :user => user, :header_text => header
    end
  end

  def task_status_style(task)
    styles = []
    styles << "display: inline"
    styles << "border-radius: 4px"
    styles << "font-size: 12px"
    styles << "color: white"
    styles << "width: 23px"
    styles << "text-align: center"
    bg_color = case task.status_name
      when "new"
        "#f3f3f3"
      when "open"
        "#f3f3f3"
      when "hold"
        "#f3f3f3)"
      when "resolved"
        "#f3f3f3"
      when "rejected"
        "#f3f3f3"
      end
    styles << "background-color:#{bg_color}"
    styles.join(";")
  end

  def task_due_on_style(task)
    styles = []
    # styles << "font-size: 11px"
    styles << "display: table-cell"
    styles << "color: rgb(200,0,0)"
    styles.join(";")
  end

  def email_navigation
    "#{organization_header_bar_colour}order-bottom-left-radius: 5px 5px; border-bottom-right-radius: 5px 5px; border-top-left-radius: 5px 5px; border-top-right-radius: 5px 5px;padding: 4px 10px;"
  end

  def inline_organization_link_colour
    #"color: ##{@organization ? @organization.settings['colours']['links'] : ''}"
    "color: #008ac0"
  end

  def inline_organization_text_colour
    "font-color: ##{@organization ? @organization.settings['colours']['text'] : ''}"
  end

  def url_to_invitation(invitation)
    if invitation.target.is_a? Project
      projects_url(:invitation => invitation.token)
    elsif invitation.target.is_a? Organization
      organizations_url(:invitation => invitation.token)
    else # @target.is_a? ProjectGroup
      project_groups_url(:invitation => invitation.token)
    end
  end


end