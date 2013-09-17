class ProjectGroupsController < ApplicationController
  before_filter :load_current_project_group, :except => [:index, :new, :create]
  before_filter :load_project_groups, :only => [:index]
  before_filter :load_pending_projects, :only => [:index, :show]
  skip_before_filter :load_project

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |f|
      flash[:error] = t('common.not_allowed')
      f.any(:html, :m) { redirect_to project_groups_path }
      handle_api_error(f, @project_group)
    end
  end


  def index
    @new_conversation = Conversation.new(:simple => true)
    @activities = Activity.for_projects(@projects)
    @threads = @activities.threads.all(:include => [:project, :target])
    @last_activity = @threads.last

    respond_to do |f|
      f.html
      f.m     { redirect_to activities_path if request.path == '/' }
      f.rss   { render :layout  => false }
      f.xml   { render :xml     => @projects.to_xml }
      f.json  { render :as_json => @projects.to_xml }
      f.yaml  { render :as_yaml => @projects.to_xml }
      f.ics   { render :text    => Project.to_ical(@projects, params[:filter] == 'mine' ? current_user : nil, request.host, request.port) }
      f.print { render :layout  => 'print' }
    end
  end

  def show
    @projects = @project_group.projects.unarchived
    @new_conversation = Conversation.new(:simple => true)
    @activities = Activity.for_projects(@projects)
    @threads = @activities.threads.all(:include => [:project, :target])
    @last_activity = @threads.last

    respond_to do |f|
      f.html
      f.m     { redirect_to activities_path if request.path == '/' }
      f.rss   { render :layout  => false }
      f.xml   { render :xml     => @projects.to_xml }
      f.json  { render :as_json => @projects.to_xml }
      f.yaml  { render :as_yaml => @projects.to_xml }
      f.ics   { render :text    => Project.to_ical(@projects, params[:filter] == 'mine' ? current_user : nil, request.host, request.port) }
      f.print { render :layout  => 'print' }
    end
  end

  def new
    authorize! :create_project, current_user
    @project_group = ProjectGroup.new
    @project_group.build_organization

    respond_to do |f|
      f.any(:html, :m)
    end
  end

  def create
    @project_group = current_user.project_groups.new(params[:project_group])
    authorize! :create_project, current_user

    respond_to do |f|
      if @project_group.save
        pg_role = @project_group.project_group_roles.build(:role => ProjectGroupRole::ROLES[:admin])
        pg_role.user_id = current_user.id
        pg_role.save!
        #f.html { redirect_to project_group_invite_people_path(@project_group) }
        #f.m { redirect_to @project_group }
        f.html { redirect_to show_all_project_groups_path }
        f.m { redirect_to show_all_project_groups_path }
      else
        flash.now[:error] = t('project_groups.new.invalid_project')
        f.any(:html, :m) { render :new }
      end
    end
  end

  def edit
    authorize! :update, @project_group
    @sub_action = params[:sub_action] || 'settings'

    respond_to do |f|
      f.any(:html, :m)
    end
  end

  def update
    authorize! :update, @project_group
    authorize!(:transfer, @project_group) if params[:sub_action] == 'ownership'
    @sub_action = params[:sub_action] || 'settings'
    #@organization = @current_project.organization if @current_project.organization

    if @project_group.update_attributes(params[:project_group])
      flash.now[:success] = t('project_groups.edit.success')
    else
      flash.now[:error] = t('project_groups.edit.error')
    end

    respond_to do |f|
      f.any(:html, :m) { render :edit }
    end
  end

  def transfer
    authorize! :transfer, @project_group

    # Grab new owner
    user_id = params[:project_group][:user_id] rescue nil
    current_user_id = @project_group.user_id
    role = @project_group.project_group_roles.find_by_user_id(user_id)
    current_user_role = @project_group.project_group_roles.find_by_user_id(current_user_id)
    saved = false

    if role.nil?
      role = @project_group.project_group_roles.new
      role.user_id = user_id
      role.role = 20
      role.save
    end

    #old_owner = @project_group.delete_current_owner
    saved = @project_group.transfer_to(role)


    #flash[:error] = @project_group.user


    if saved
      current_user_role.destroy
      respond_to do |f|
        flash[:notice] = I18n.t('projects.edit.transferred')
        f.html { redirect_to show_all_project_groups_path(:archived_projects => false) }
        handle_api_success(f, @project_group)
      end
    else
      respond_to do |f|
        flash[:error] = I18n.t('projects.edit.invalid_transferred')
        f.html { redirect_to show_all_project_groups_path(:archived_projects => false) }
        handle_api_error(f, @project_group)
      end
    end
  end

  def destroy
    authorize! :destroy, @project_group
    @project_group.destroy
    respond_to do |f|
      f.any(:html, :m) {
        flash[:success] = t('project_groups.edit.deleted')
        redirect_to projects_path
      }
    end
  end

  def show_all
    @archived_projects = false
    @archived_projects = true if (!params[:archived_projects].nil? and params[:archived_projects])
    projects1 = [] #project groups containing >= 1 projects
    projects2 = [] #project groups containing 0 projects
    @people = Person.where(:user_id => current_user.id)
    @people.each do |person|
      project = Project.find(person.project_id)
      begin
        projectGroup = ProjectGroup.find(project.project_group_id)
      rescue
        projectGroup == -1
      end
      projects1.push([projectGroup, project, person.role]) if ((@archived_projects or !project.archived) and projectGroup != -1 and not projectGroup.nil?)
    end
    project_groups = ProjectGroup.all
    project_groups.each do |pg|
      project_group_visible = false
      projects1.each do |p|
        project_group_visible = true if p[0] and pg.id == p[0].id
      end
      if (!project_group_visible)
        pgr = ProjectGroupRole.where(:project_group_id => pg.id, :role => 20)
        projects2.push([pg, nil, nil]) if ((pgr.count > 0  and pgr.first.user_id == current_user.id) or pg.user_id == current_user.id)
      end
    end
    projects1.sort! {|x,y| x[0].name <=> y[0].name }
    projects2.sort! {|x,y| x[0].name <=> y[0].name }
    @projects = projects1.concat(projects2)
  end

  def settings
    @project_group = ProjectGroup.find(params[:project_group_id])
    if (!check_owner_project_group(@project_group))
      flash[:error] = t('project_groups.settings.not_owner_error')
      redirect_to root_path
    end
  end

  def update_name
    pg = ProjectGroup.find(params[:project_group_id])
    if (check_owner_project_group(pg))
      pg.name = params[:project_group_name]
      pg.save
      flash[:success] = t('project_groups.settings.success_update_name')
      redirect_to settings_project_group_path(:project_group_id => pg.id)
    else
      flash[:error] = t('project_groups.settings.not_owner_error')
      redirect_to root_path
    end
  end

  protected
  
  def load_current_project_group
    if project_group_id = params[:project_group_id] || params[:id]
      unless @project_group = ProjectGroup.find_by_id_or_permalink(project_group_id)
        flash[:error] = t('not_found.project_group', :id => project_group_id)
        redirect_to project_groups_path
      end
    end
  end

  def load_project_groups
    @project_groups = current_user.project_groups
    @projects = @project_groups.collect{|g| g.projects.unarchived}.flatten
  end

  def load_pending_projects
    @pending_projects = @current_user.invitations.pending_projects + @current_user.invitations.pending_project_groups
  end

  private

  def check_owner_project_group(project_group)
    project_group.user_id == current_user.id
  end

end
