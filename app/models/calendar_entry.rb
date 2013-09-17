class CalendarEntry < ActiveRecord::Base
  has_one :event

  after_create :create_calendar_event
  after_update :update_calendar_event
  after_destroy :destroy_calendar_event

  def create_calendar_event
    e = Event.new
    e.name = title
    e.start_at = start_date
    e.end_at = end_date
    e.calendar_entry_id = id
    e.save
  end

  def update_calendar_event
    e = Event.where(:calendar_entry_id => id).first
    e.name = title
    e.start_at = start_date
    e.end_at = end_date
    e.save
  end

  def destroy_calendar_event
    e = Event.where(:calendar_entry_id => id).first
    e.destroy
  end
end
