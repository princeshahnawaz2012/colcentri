class TasksController < ApplicationController

  around_filter :set_time_zone, :only => [:show]
  before_filter :load_task, :except => [:new, :create]
  before_filter :can_see_task?, :only => [:show]
  before_filter :load_task_list, :only => [:new, :create]
  before_filter :set_page_title
  #skip_before_filter :load_project, :only => [:reorder]
  
  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def show
    respond_to do |f|
      f.any(:html, :m)
      f.js {
        @show_part = params[:part]
        render :template => 'tasks/reload'
      }
      f.xml  { render :xml     => @task.to_xml }
      f.json { render :as_json => @task.to_xml }
      f.yaml { render :as_yaml => @task.to_xml }
    end
  end

  def new
    authorize! :make_tasks, @current_project
    @task = @task_list.tasks.new
    respond_to do |f|
      f.any(:html, :m)
    end
  end

  def create
    authorize! :make_tasks, @current_project
    @task = @task_list.tasks.create_by_user(current_user, params[:task])

    #the participants information is created in the DB
    participants = (@task.task_participants).split(',')
    participants.each do |participant|
      u = User.find_by_login(participant)
      if (not u.nil?)
        tp = TaskParticipant.new
        tp.task_id = @task.id
        tp.user_id = u.id
        tp.save
      end
    end

    respond_to do |f|
      f.any(:html, :m) {
        if @task.new_record?
          render :new
        else
          redirect_to_task_list
        end
      }
      f.js {
        if @task.new_record?
          output_errors_json(@task)
        else
          render(:partial => 'tasks/task', :locals => {
            :project => @current_project,
            :task_list => @task_list,
            :task => @task.reload,
            :editable => true
          })
        end
      }
    end

  end

  def edit
    authorize! :update, @task
    respond_to do |f|
      f.any(:html, :m)
      f.js { render :layout => false }
    end
  end

  def update
    if can? :update, @task
      can? :update, @task
      @task.updating_user = current_user
      success = @task.update_attributes params[:task]
    elsif can? :comment, @task
      @task.updating_user = current_user
      success = @task.update_attributes(:comments_attributes => params['task']['comments_attributes'])
    else
      authorize! :comment, @task
    end

    #the participants information is created in the DB
    task_participants = TaskParticipant.where(:task_id => @task.id)
    task_participants.each do |tp|
      tp.destroy
    end
    begin
      participants = (task_participants).split(',')
    rescue
      participants = []
    end
    participants.each do |participant|
      u = User.find_by_login(participant)
      if (not u.nil?)
        tp = TaskParticipant.new
        tp.task_id = @task.id
        tp.user_id = u.id
        tp.save
      end
    end

    respond_to do |f|
      f.any(:html, :m) {
        if request.xhr? or iframe?
          if @task.comment_created?
            comment = @task.comments(true).first
            response.headers['X-JSON'] = @task.to_json(:include => :assigned)

            render :partial => 'comments/comment',
              :locals => { :comment => comment, :threaded => true }
          else
            render :nothing => true
          end
        else
          if success
            #if params[:controller] == 'task_lists' and params[:action] != 'my_tasks'
            redirect_to project_task_lists_path(@project)
            #else
            #  redirect_to my_tasks_path
            #end
          else
            render :edit
          end
        end
      }
      f.js {
        if params[:task][:name]
          head :ok
        end
      }
    end
  end

  def destroy
    authorize! :destroy, @task
    #@task.destroy
    # nothing
    @task.deleted = true
    @task.save
    #we don't want to mark the comments as deleted because if we do they won't appear in the recent activity view
=begin
    Comment.where(:target_id => @task.id).each do |c|
      c.deleted = true
      c.save
    end
=end

    respond_to do |f|
      f.any(:html, :m) {
        flash[:success] = t('deleted.task', :name => @task.to_s)
        redirect_to [@current_project, @task_list]
      }
      f.js { render :layout => false }
      handle_api_success(f, @task)
    end
  end

  def reorder

=begin
    v = Organization.find(2)
    v.name = "b"
    v.permalink = "b"
    v.save(false)
=end

    authorize! :reorder_objects, @current_project

=begin
    v.name = "c"
    v.permalink = "c"
    v.save(false)
=end

    #target_task_list = @current_project.task_lists.find params[:task_list_id]
    target_task_list= @current_project.task_lists.find(9)

=begin
    v.name = "d"
    v.permalink = "d"
    v.save(false)
=end

    if @task.task_list != target_task_list
      @task.task_list = target_task_list
      @task.save
    end

=begin
    v.name = "e"
    v.permalink = "e"
    v.save(false)
=end

    task_ids = params[:task_ids].split(',').collect {|t| t.to_i}
    target_task_list.tasks.each do |t|
      next unless task_ids.include?(t.id)
      t.position = task_ids.index(t.id)
      t.save
    end

=begin
    v.name = "f"
    v.permalink = "f"
    v.save(false)
=end

    head :ok

=begin
    v.name = "g"
    v.permalink = "g"
    v.save(false)
=end
  end

  def watch
    authorize! :watch, @task
    @task.add_watcher(current_user)
    respond_to do |f|
      f.js { render :layout => false }
    end
  end

  def unwatch
    @task.remove_watcher(current_user)
    respond_to do |f|
      f.js { render :layout => false }
    end
  end

  private

    def load_task_list
      @task_list = if params[:id]
        @current_project.tasks.find(params[:id]).task_list
      elsif params[:task_list_id]
        @current_project.task_lists.find params[:task_list_id]
      end
    end

    def load_task
      @task = @current_project.tasks.find params[:id]
      @comments = @task.get_visible_comments(@current_user)
      @task_list = @task.task_list
    end
    
    def redirect_to_task
      redirect_to [@current_project, @task]
    end

    def can_see_task?
      authorize! :see, @task
    end
end
