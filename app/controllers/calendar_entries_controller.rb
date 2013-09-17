class CalendarEntriesController < ApplicationController
  def new
  end

  def create
    ce = CalendarEntry.new
    ce.title = params[:title]
    ce.description = params[:description] if !params[:description].nil?
    ce.end_date = Time.utc(params[:end_date][:year].to_i, params[:end_date][:month].to_i, params[:end_date][:day].to_i)
    if (params[:valid_start_date])
      ce.start_date = Time.utc(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
    else
      ce.start_date = ce.end_date
    end
    ce.user_id = current_user.id
    ce.save
    redirect_to calendar_path
  end

  def show
    @entry = CalendarEntry.find(params[:entry_id])
    if (!check_current_user_is_owner(@entry))
      flash[:error] = t('calendar_entries.show.not_owner_error')
      redirect_to calendar_path
    end
  end

  def delete
    entry = CalendarEntry.find(params[:entry_id])
    if (check_current_user_is_owner(entry))
      entry.destroy
    else
      flash[:error] = t('calendar_entries.show.delete_error')
    end
    redirect_to calendar_path
  end

  def edit
    @entry = CalendarEntry.find(params[:entry_id])
    if (!check_current_user_is_owner(@entry))
      flash[:error] = t('calendar_entries.show.edit_error')
      redirect_to calendar_path
    end
  end

  def update
    entry = CalendarEntry.find(params[:entry_id].to_i)
    if (check_current_user_is_owner(entry))
      entry.title = params[:title]
      entry.description = params[:description] unless params[:description].nil?
      entry.end_date = Time.utc(params[:end_date][:year].to_i, params[:end_date][:month].to_i, params[:end_date][:day].to_i)
      entry.start_date = Time.utc(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
      if (params[:valid_start_date])
        entry.start_date = Time.utc(params[:start_date][:year].to_i, params[:start_date][:month].to_i, params[:start_date][:day].to_i)
      else
        entry.start_date = entry.end_date
      end
      entry.save
      redirect_to calendar_path
    else
      flash[:error] = t('calendar_entries.show.edit_error')
      redirect_to calendar_path
    end
  end

  private
    def check_current_user_is_owner(calendar_entry)
      calendar_entry.user_id == current_user.id
    end
end