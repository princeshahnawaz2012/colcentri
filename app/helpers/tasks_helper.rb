module TasksHelper

  def task_classes(task)
    [].tap do |classes|
      classes << 'due_today' if task.due_today?
      classes << 'due_tomorrow' if task.due_tomorrow?
      classes << 'due_week' if task.due_in?(1.weeks)
      classes << 'due_2weeks' if task.due_in?(2.weeks)
      classes << 'due_3weeks' if task.due_in?(3.weeks)
      classes << 'due_month' if task.due_in?(1.months)
      classes << 'overdue' if task.overdue?
      classes << 'unassigned_date' if task.due_on.nil?
      classes << "status_#{task.status_name}"
      classes << (task.assigned.nil? ? 'unassigned' : "user_#{task.assigned.user_id}")
    end.join(' ')
  end

  def validation_new_task
   javascript_tag <<-EOS


    #name_cant_be_blank = t('tasks.errors.name.cant_be_blank')
    #description_cant_be_blank = t('tasks.errors.description.cant_be_blank')

   EOS
  end

  def sidebar_tasks(tasks)
    render :partial => 'tasks/task_sidebar',
      :as => :task,
      :collection => tasks#.sort { |a,b| (a.due_on || 1.year.from_now.to_date) <=> (b.due_on || 1.year.from_now.to_date) }
    # Because of the way this sort is implemented, it might be redundant
  end

  def render_due_on(task,user)
    render 'tasks/due_on', :task => task, :user => user
  end

  def render_assignment(task,user)
    render 'tasks/assigned', :task => task, :user => user
  end
  
  def task_status_badge(name)
    content_tag(:span, localized_status_name(name), :class => "task_status task_status_#{name}")
  end

  def task_priority_badge(name)
    content_tag(:span, localized_priority_name(name), :class => "task_priority task_priority_#{name}")
  end

  def comment_task_status(comment)
    if comment.initial_status? or comment.status_transition?
      [].tap { |out|
        if comment.status_transition?
          out << task_status_badge(comment.previous_status_name) if comment.previous_status_name != :new
          out << content_tag(:span, '&rarr;'.html_safe, :class => "arr status_arr")
        end
        out << task_status_badge(comment.status_name)
      }.join(' ').html_safe
    end
  end

  def comment_task_priority(comment)
    if comment.initial_priority? or comment.priority_transition?
      [].tap { |out|
        if comment.priority_transition?
          out << task_priority_badge(comment.previous_priority_name)
          out << content_tag(:span, '&rarr;'.html_safe, :class => "arr status_arr")
        end
        out << task_priority_badge(comment.priority_name)
      }.join(' ').html_safe
    end
  end

  def comment_task_start_date(comment)
    if comment.start_date_change?
      transition = false
      [].tap { |out|
        if comment.start_date_transition?
          transition = true
          out << t('comments.new.start_date') + ': ' + span_for_start_date(comment.previous_start_date)
          out << content_tag(:span, '&rarr;'.html_safe, :class => "arr start_date_arr")
        end
        if transition
          out << span_for_start_date(comment.start_date)
        else
          out << t('comments.new.start_date') + ': ' + span_for_start_date(comment.start_date)
        end
      }.join(' ').html_safe
    end
  end

  def comment_task_due_on(comment)
    if comment.due_on_change?
      transition = false
      [].tap { |out|
        if comment.due_on_transition?
          transition = true
          out << t('comments.new.due_on') + ': ' + span_for_due_date(comment.previous_due_on)
          out << content_tag(:span, '&rarr;'.html_safe, :class => "arr due_on_arr")
        end
        if transition
          out << span_for_due_date(comment.due_on)
        else
          out << t('comments.new.due_on') + ': ' + span_for_due_date(comment.due_on)
        end
      }.join(' ').html_safe
    end
  end

  def comment_task_participants(comment)
    if comment.initial_participants? or comment.task_participants_transition?
      [].tap { |out|
        out << t('comments.new.participants') + ": " + content_tag(:span, comment.previous_task_participants, :class => "task_participants")
        out << content_tag(:span, '&rarr;'.html_safe, :class => "arr participants_arr")
        out << content_tag(:span, comment.task_participants, :class => "task_participants")
      }.join(' ').html_safe
    end
  end

  def task_status(task,status_type)
    status_for_column = status_type == :column ? "task_status_#{task.status_name}" : "task_counter"
    out = %(<span data-task-id=#{task.id} class='task_status #{status_for_column}'>)
    out << case status_type
    when :column  then localized_status_name(task)
    when :content then task.comments_count.to_s
    when :header  then localized_status_name(task)
    end
    out << %(</span>)
    out.html_safe
  end

  def start_date(task)
    t('tasks.start_date') + ': ' + I18n.l(task.start_date, :format => '%b %d') unless (task.start_date.nil?)
  end

  def due_on(task)
    if task.overdue? && task.overdue <= 5
      t('tasks.overdue', :days => task.overdue)
    else
      t('tasks.end_date') + ': ' + I18n.l(task.due_on, :format => '%b %d') unless (task.due_on.nil?)
    end
  end

  def list_tasks(task_list, tasks,editable=true)
    render tasks,
      :project => task_list && task_list.project,
      :task_list => task_list,
      :editable => editable
  end

  def localized_status_name(task_or_status)
    task_or_status = task_or_status.status_name if task_or_status.respond_to? :status_name
    t("tasks.status.#{task_or_status}")
  end

  def localized_status_name_from_index(status_index)
    localized_status_name(Task::STATUS_NAMES[status_index])
  end

  def localized_priority_name(priority)
    t("tasks.priority.#{priority}")
  end

  def task_priorities_for_select
    task_priorities = []
    Task::PRIORITIES_NAMES.each_with_index.map { |name, code|
      task_priorities.push([localized_priority_name(name), code])
    }
    task_priorities
  end
  
  def task_statuses_for_select
=begin
    Task::STATUS_NAMES.each_with_index.map { |name, code|
      [localized_status_name(name), code]
    }
=end
    #now we do not want to use the 'new' status
    status_names_without_new = []
    Task::STATUS_NAMES.each_with_index.map { |name, code|
      status_names_without_new.push([localized_status_name(name), code]) if code != 0
    }
    status_names_without_new
  end

  def time_tracking_doc
    #link_to(t('projects.fields.new.time_tracking_docs'), "http://help.colcentric.com/faqs/advanced-features/time-tracking", :target => '_blank')
  end

  def date_picker(f, field, embedded = false, html_options = {})
    date_field = f.object.send(field) ? localize(f.object.send(field), :format => :long) : "<i>#{t('date_picker.no_date_assigned')}</i>".html_safe
    div_id = "#{f.object.class.to_s.underscore}_#{f.object.id}_#{field}"
    content_tag :div, :class => "date_picker #{'embedded' if embedded}", :style => 'float: left; margin-left: 2px' do

      f.hidden_field(field, html_options) << content_tag(:span, date_field, :class => 'localized_date')
    end
  end
  
  def embedded_date_picker(f, field)
    date_field = f.object.send(field) ? localize(f.object.send(field), :format => :long) : "<i>#{t('date_picker.no_date_assigned')}</i>".html_safe
    div_id = "#{f.object.class.to_s.underscore}_#{f.object.id}_#{field}"
    content_tag :div, :class => "date_picker_embedded", :id => div_id do
      f.hidden_field(field) << content_tag(:span, date_field, :class => 'localized_date', :style => 'display: none') <<
      javascript_tag("new CalendarDateSelect( $('#{div_id}').down('input'), $('#{div_id}').down('span'), {buttons:true, embedded:true, time:false, year_range:[2008, 2020]} )")
    end
  end
  
  def value_for_assigned_to_select
    params[:assigned_to] == 'all' ? 'task' : (params[:assigned_to] || 'task')
  end

  def can_see_task?(task)
    can? :see, task
  end


  protected

    def span_for_due_date(due_date)
      content_tag(:span, due_date ?
          localize(due_date, :format => :short) :
          t('tasks.due_on.undefined'),
        :class => "assigned_date")
    end

    def span_for_start_date(start_date)
      content_tag(:span, start_date ?
          localize(start_date, :format => :short) :
          t('tasks.due_on.undefined'),
        :class => "assigned_date")
    end
end
