class Event < ActiveRecord::Base
  has_one :task
  has_one :calendar_entry
  has_event_calendar

  def permalink_task_project
    t = Task.find(task_id)
    Project.find(t.project_id).permalink
  end
end
