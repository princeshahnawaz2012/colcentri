class Comment
    
  def previously_closed?
    [:rejected, :resolved].include? previous_status_name
  end
  
  def transition?
    status_transition? || assigned_transition? || due_on_change? || priority_transition? || task_participants_transition?
  end

  def initial_status?
    status? and not previous_status?
  end

  def initial_priority?
    priority? and not previous_priority?
  end

  def initial_participants?
    task_participants? and not previous_task_participants?
  end

  def due_on_transition?
    due_on != previous_due_on and !previous_due_on.nil?
  end

  def due_on_transition2?
    due_on != previous_due_on
  end

  def task_participants_transition?
    task_participants != previous_task_participants
  end

  def due_on_change?
    due_on != previous_due_on
  end

  def start_date_transition?
    start_date != previous_start_date and !previous_start_date.nil?
  end

  def start_date_transition2?
    start_date != previous_start_date and !previous_start_date.nil?
  end

  def start_date_change?
    start_date != previous_start_date
  end

  def assigned_transition?
    assigned_id != previous_assigned_id
  end
  
  def status_transition?
    previous_status && status != previous_status
  end

  def priority_transition?
    previous_priority && priority != previous_priority
  end

  def assigned?
    !assigned.nil?
  end

  def previous_assigned?
    !previous_assigned.nil?
  end

  def due_on?
    !due_on.nil?
  end

  def previous_due_on?
    !previous_due_on.nil?
  end

  def status_open?
    Task::STATUSES[:open] == status
  end

  def previous_status_open?
    Task::STATUSES[:open] == previous_status
  end
  
  def status_name
    Task::STATUS_NAMES[status || 0]
  end
  
  def previous_status_name
    Task::STATUS_NAMES[previous_status]
  end

  def priority_name
    Task::PRIORITIES_NAMES[priority || 1]
  end

  def previous_priority_name
    Task::PRIORITIES_NAMES[previous_priority]
  end

end