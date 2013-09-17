module ProjectsHelper

  extend ActiveSupport::Memoizable

  def jsProjectFormValidation
    javascript_tag <<-EOS
      function validate_project_name(form) {
        var res = true;

        var project_name = form.project_name.value;

        if (project_name.length > 30){
          res = false;
          Element.show('project_error_max_length');
          Element.hide('project_error_no_length');
          form.project_name.up(0).setAttribute("class", "field_with_errors");
        }else if (project_name.length < 1){
          res = false;
          Element.show('project_error_no_length');
          form.project_name.up(0).setAttribute("class", "field_with_errors");
          Element.hide('project_error_max_length');
        }else{
          Element.hide('project_error_max_length');
          Element.hide('project_error_no_length');
        }

        return res;
    }

    EOS
  end

  


  # Is it used??
  def delete_project_link(project)
    link_to '',
    project_path(project),
    :method => :delete,
    :class => 'big_trash_icon',
    :title => t('projects.fields.forever'),
    :confirm => t('projects.fields.confirm_delete')
  end

  def edit_project_link(project, sub_action)
    case sub_action
      when 'settings' then project_settings_path(project)
      when 'deletion' then project_deletion_path(project, :sub_action => 'deletion')
      when 'ownership' then project_ownership_path(project, :sub_action => 'ownership')
    end

  end

  def archive_project_link(project)
    link_to_function content_tag(:span,t('projects.fields.archiving')), 
      "$('project_archived').value = 1; $('content').down('.edit_project').submit();",
      :class => 'button'
  end
  
  def permalink_example(permalink)
    out = host_with_protocol + projects_path + '/'
    out << content_tag(:span, permalink, :id => 'handle', :class => 'good')
    content_tag(:div, out.html_safe, :id => 'preview')
  end

  def watch_permalink_example
    javascript_tag "$('project_permalink').observe('keyup', function(e) { Project.valid_url(); })"    
  end

  def list_users_statuses(users)
    render :partial => 'users/status', :collection => users, :as => :user
  end
  
  def new_project_link
    if !Colcentric.config.community || (@community_organization && @community_role && @community_role >= 20)
      link_to content_tag(:span, t('.new_project')), new_project_path,
        :class => 'add_button', :id => 'new_project_link'
    end
  end


  # Is it used?? - Yes
  def project_fields(f,project,sub_action='new')
    render "projects/fields/#{sub_action}",  :f => f, :project => project
  end
   
  def instructions_for_feeds
    link_to t('shared.instructions.subscribe_to_feeds'), feeds_path, :class => :subscribe
  end

  def subscribe_to_all_projects_link
    link_to t('.subscribe_to_all'),
      user_rss_token(projects_path(:format => :rss)),
      :class => 'subscribe subscribe_all'
  end

  def subscribe_to_project_link(project)
    link_to t('.subscribe_to_project', :project => project),
      user_rss_token(project_path(project, :format => :rss)),
      :class => :subscribe
  end

  def instructions_for_calendars
    link_to t('shared.instructions.subscribe_to_calendars'), calendars_path, :class => :calendars_link
  end

  def instructions_for_email(project)
    suffix = ''
    case location_name
      when 'show_projects' #project@app.colcentric.com
        email_help = t('shared.instructions.send_email_help_project_html', :email => "#{project.permalink}@#{Colcentric.config.smtp_settings[:domain]}")
      when 'show_tasks' #project+task+12@app.colcentric.com
        email_help = t('shared.instructions.send_email_help_task_html', :email => "#{project.permalink}+task+#{@task.id}@#{Colcentric.config.smtp_settings[:domain]}")
      when 'index_conversations' #project+conversation@app.colcentric.com
        email_help = t('shared.instructions.send_email_help_conversations_html', :email => "#{project.permalink}+conversation@#{Colcentric.config.smtp_settings[:domain]}")
        suffix = '_conversations'
      when 'new_conversations' #project+conversation@app.colcentric.com
        email_help = t('shared.instructions.send_email_help_conversations_html', :email => "#{project.permalink}+conversation@#{Colcentric.config.smtp_settings[:domain]}")
        suffix = '_conversations'
      when 'show_conversations' #project+conversation+5@app.colcentric.com
        email_help = t('shared.instructions.send_email_help_conversation_html', :email => "#{project.permalink}+conversation+#{@conversation.id}@#{Colcentric.config.smtp_settings[:domain]}")
    end

    if email_help
      span = content_tag(:span, :id => 'email_help', :style => 'display:none') do
        %(<p>#{email_help}</p><a href='#' class='closeThis'>#{t('common.close')}</a>).html_safe
      end
      link_to_function(t('shared.instructions.send_email' + suffix),
        ("$('email_help').toggle()".html_safe), :class => :email_link) + span
    end
  end

  def subscribe_to_all_calendars_link
    content_tag(:div,
      (t('.subscribe_to_all') +
      link_to(t('shared.task_navigation.all_tasks'), user_rss_token(projects_path(:format => :ics))) +
      ' ' + t('common.or') + ' ' +
      link_to(t('shared.task_navigation.my_assigned_tasks'), user_rss_token(projects_path(:format => :ics), 'mine'))).html_safe,
      :class => 'calendar_links_all')
  end

  def subscribe_to_calendar_link(project)
    content_tag(:div,
      (t('.subscribe_to_project', :project => h(project)) +
      link_to(t('shared.task_navigation.all_tasks'), user_rss_token(project_path(project, :format => :ics))) +
      ' ' + t('common.or') + ' ' +
      link_to(t('shared.task_navigation.my_assigned_tasks'), user_rss_token(project_path(project, :format => :ics), 'mine'))).html_safe,
      :class => :calendar_links)
  end

  def leave_project_link(project)
    unless project.user == current_user
      link_to t('people.column.leave_project'),
        project_person_path(project, current_user.people.detect { |p| p.project_id == project.id }),
        :method => :delete, :confirm => t('people.column.confirm_delete'), :class => :leave_link
    end
  end

  def reset_autorefresh
    "clearInterval(autorefresh)"
  end

  def autorefresh(activities, project = nil)
    first_id = Array(activities).first.id
    
    ajax_request = if project
      remote_function(:url => project_show_new_path(project, first_id))
    else
      remote_function(:url => show_new_path(first_id))
    end

    interval = Colcentric.config.autorefresh_interval*1000

    "autorefresh = setInterval(\"#{ajax_request}\", #{interval})"
  end

  def options_for_owner(people)
    people.map {|person| [ person.login, person.user_id ]}
  end
  
  def options_for_projects(projects)
    projects.map {|project| [ project.name, project.id ]}
  end
  
  def options_for_owned_projects(user, projects)
    projects.reject{|p| p.user_id != user.id}.map {|p| [ p.name, p.id ]}
  end

  def options_for_project_personalization
    Project::PERSONALIZATION.map { |personalization, value| [t("projects.personalization.#{personalization}"), value] }.sort_by(&:last)
  end

  # FIXME eventually migrate that to just use the plain json from projects_people_data
  def autocomplete_projects_people_data
    projects = @current_project ? [@current_project] : current_user.projects.reject{ |p| p.new_record? }
    return nil if projects.empty?
    
    format = '@%s <span class="informal">%s</span>'
    special_all = format % ['all', t('conversations.watcher_fields.people_all')]
    data_by_permalink = Hash.new { |h, k| h[k] = [special_all] }
    
    rows = Person.user_names_from_projects(projects)
    
    names = rows.each_with_object(data_by_permalink) do |(project_id, login, first_name, last_name), data|
      data[project_id] << (format % [login, "#{h first_name} #{h last_name}"])
    end
    
    javascript_tag "_people_autocomplete = #{names.to_json}"
  end

  def projects_people_data
    projects = @current_project ? [@current_project] : current_user.projects.reject{ |p| p.new_record? }
    return nil if projects.empty?
    data = {}
    rows = Person.user_names_from_projects(projects, current_user)
    rows.each do |project_id, login, first_name, last_name, person_id, user_id|
      data[project_id] ||= []
      data[project_id] << [person_id.to_s, login, "#{h first_name} #{h last_name}", user_id]
    end
    javascript_tag "_people = #{data.to_json}"
  end

  def commentable_projects
    @projects.select { |p| p.commentable?(current_user) and not p.archived? }
  end
  memoize :commentable_projects

end
