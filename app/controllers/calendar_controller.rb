class CalendarController < ApplicationController

  before_filter :check_project_archived, :only => [:project_calendar]

  def check_project_archived
    if (!params[:project].nil?)
      project_id = params[:project].to_i
    else
      pr = Project.where(:permalink => params[:project_permalink]).first
      project_id = pr.id
    end

    begin
      @project = Project.find(project_id)
    rescue
      @project = -1
    end

    if @project.archived? and not @project == -1
      if @project.user_id != current_user.id
        flash[:error] = t('errors.projects.archived')
        redirect_to show_all_project_groups_path(:archived_projects => false)
      else
        redirect_to project_settings_path(@project.permalink)
      end
    end
  end


  def index
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i
    @shown_month = Date.civil(@year, @month)
    @user_projects = current_user.projects.sort_by(&:name)
    @category = params[:category]
    @project = params[:project]

    #a project that represents all of the user projects is created with id = 0
    p = Project.new
    p.id = 0
    p.name = t('calendar.index.all')
    @user_projects.insert(0, p)
    p = Project.new
    p.id = 0
    p.name = t('calendar.index.project')
    @user_projects.insert(0, p)

    @first_day_of_week = 1
    strip_start, strip_end = Event.get_start_and_end_dates(@shown_month, @first_day_of_week)
    events = Event.events_for_date_range(strip_start, strip_end, {})
    people = Person.where(:user_id => current_user.id)
    @events_aux = Array.new
    events.each do |event|
      if (!event.task_id.nil? and (params[:category].nil? or params[:category] == t('calendar.index.all') or
          params[:category] == t('calendar.index.task') or params[:category] == t('calendar.index.category'))) #The calendar event is associated with a task
        marked = false
        people.each do |person|
          if (Task.find(event.task_id).assigned_id == person.id) #if the user is the responsible of the task
            if (params[:project].nil? or params[:project].to_i == 0 or params[:project].to_i == Task.find(event.task_id).project_id)
              @events_aux.push(event) if Task.find(event.task_id).status == 1
              marked = true
            end
          end
        end
        if (not marked and TaskParticipant.where(:user_id => current_user.id, :task_id => event.task_id).count > 0) #if the user is a participant
          @events_aux.push(event) if Task.find(event.task_id).status == 1
        end
      elsif (!event.calendar_entry_id.nil? and (params[:category].nil? or params[:category] == t('calendar.index.all') or
          params[:category] == t('calendar.index.entry') or params[:category] == t('calendar.index.category'))) #The calendar event is associated with a calendar entry
        if (CalendarEntry.find(event.calendar_entry_id).user_id == current_user.id)
          @events_aux.push(event)
        end
      end
    end
    @event_strips = Event.create_event_strips(strip_start, strip_end, @events_aux)
  end

  def collaboration_calendar
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i
    @shown_month = Date.civil(@year, @month)
    @project = params[:project]
    @responsible = params[:responsible]
    responsible_id = 0
    responsible_id = User.where(:login => @responsible).first.id if (@responsible != t('calendar.index.all') and @responsible != t('calendar.index.responsible') and not @responsible.nil?)
    @user_projects = current_user.projects.sort_by(&:name)
    @users = Array.new

    #a project that represents all of the user projects is created with id = 0
    p = Project.new
    p.id = 0
    p.name = t('calendar.index.all')
    @user_projects.insert(0, p)
    p = Project.new
    p.id = 0
    p.name = t('calendar.index.project')
    @user_projects.insert(0, p)

    ids_users_in_same_projects = Array.new()
    people = Person.where(:user_id => current_user.id)
    people.each do |p|
      people2 = Person.where(:project_id => p.project_id)
      people2.each do |p2|
        ids_users_in_same_projects.push(p2.user_id)
      end
    end
    ids_users_in_same_projects.uniq!

    ids_users_in_same_projects.each do |id|
      @users.push(User.find(id).login)
    end
    @users.sort! {|a,b| a.downcase <=> b.downcase}
    @users.insert(0, t('calendar.index.all'))
    @users.insert(0, t('calendar.index.responsible'))

    first_day_of_week = 1
    strip_start, strip_end = Event.get_start_and_end_dates(@shown_month, first_day_of_week)
    events = Event.events_for_date_range(strip_start, strip_end, {})
    people = Person.where(:user_id => current_user.id)
    @events_aux = Array.new
    events.each do |event|
      if (!event.task_id.nil?) #The calendar event is associated with a task
        task = Task.find(event.task_id)
        if (task.status == 1)
          responsible = false
          if (responsible_id != 0)
            people = Person.where(:user_id => responsible_id)
            people.each do |person|
              responsible = true if (Task.find(event.task_id).assigned_id == person.id)
            end
          end
          if (responsible_id == 0 or responsible)
            if (params[:project].nil? or params[:project].to_i == 0 or params[:project].to_i == task.project_id)
              project = Project.find(task.project_id)
              if (Person.where(:user_id => current_user.id, :project_id => project.id).count > 0) #if the current user participates in the project
                @events_aux.push(event)
              end
            end
          end
        end
      end
    end
    @event_strips = Event.create_event_strips(strip_start, strip_end, @events_aux)
  end

  def project_calendar
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i
    @shown_month = Date.civil(@year, @month)
    if (!params[:project].nil?)
      @project = params[:project].to_i
    else
      pr = Project.where(:permalink => params[:project_permalink]).first
      @project = pr.id
    end
    @responsible = params[:responsible]
    responsible_id = 0
    responsible_id = User.where(:login => @responsible).first.id if (@responsible != t('calendar.index.all') and @responsible != t('calendar.index.responsible') and not @responsible.nil?)
    @users = Array.new

    ids_users_in_same_projects = Array.new()
    people = Person.where(:user_id => current_user.id, :project_id => @project )
    people.each do |p|
      people2 = Person.where(:project_id => p.project_id)
      people2.each do |p2|
        ids_users_in_same_projects.push(p2.user_id)
      end
    end
    ids_users_in_same_projects.uniq!

    ids_users_in_same_projects.each do |id|
      @users.push(User.find(id).login)
    end

    @users.sort! {|a,b| a.downcase <=> b.downcase}
    @users.insert(0, t('calendar.index.all'))
    @users.insert(0, t('calendar.index.responsible'))

    first_day_of_week = 1
    strip_start, strip_end = Event.get_start_and_end_dates(@shown_month, first_day_of_week)
    events = Event.events_for_date_range(strip_start, strip_end, {})
    people = Person.where(:user_id => current_user.id)
    @events_aux = Array.new
    events.each do |event|
      if (!event.task_id.nil?) #The calendar event is associated with a task
        task = Task.find(event.task_id)
        if (task.status == 1)
          responsible = false
          if (responsible_id != 0)
            people = Person.where(:user_id => responsible_id)
            people.each do |person|
              responsible = true if (Task.find(event.task_id).assigned_id == person.id)
            end
          end
          if (responsible_id == 0 or responsible)
            if (@project == task.project_id)
              project = Project.find(task.project_id)
              if (Person.where(:user_id => current_user.id, :project_id => project.id).count > 0) #if the current user participates in the project
                @events_aux.push(event)
              end
            end
          end
        end
      end
    end
    @event_strips = Event.create_event_strips(strip_start, strip_end, @events_aux)
  end

end
