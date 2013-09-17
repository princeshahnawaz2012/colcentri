module CalendarHelper
  def month_link(month_date, category, project, responsible)
    link_to(I18n.localize(month_date, :format => "%B"), {:month => month_date.month, :year => month_date.year, :category => category, :project => project, :responsible => responsible})
  end
  
  # custom options for this calendar
  def event_calendar_opts(category, project, responsible)
    { 
      :year => @year,
      :month => @month,
      :event_strips => @event_strips,
      :month_name_text => I18n.localize(@shown_month, :format => "%B %Y"),
      :previous_month_text => "<< " + month_link(@shown_month.prev_month, category, project, responsible),
      :next_month_text => month_link(@shown_month.next_month, category, project, responsible) + " >>"    }
  end

  def event_calendar(category, project, responsible)
    # args is an argument hash containing :event, :day, and :options
    calendar event_calendar_opts(category, project, responsible) do |args|
      event = args[:event]
      if event.calendar_entry_id.nil?
        %(<a href="#{project_task_path(event.permalink_task_project, event.task_id)}">#{h(event.name)}</a>)
      else
        %(<a href="#{show_calendar_entry_path(:entry_id => event.calendar_entry_id)}">#{h(event.name)}</a>)
      end
    end
  end

  def jsActivateSelectProject
    javascript_tag <<-EOS
      function activateSelectProject(form) {
        if (form.category.value == '#{t('calendar.index.all')}' || form.category.value == '#{t('calendar.index.task')}' || form.category.value == '#{t('calendar.index.category')}') {
          form.project.disabled = false;
        }
        else {
          form.project.disabled = true;
        }
      }
    EOS
  end
end
