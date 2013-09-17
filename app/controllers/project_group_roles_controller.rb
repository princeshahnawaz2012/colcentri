class ProjectGroupRolesController < ApplicationController
  before_filter :load_project_group
  before_filter :load_group_role, :only => [:update, :destroy]
  before_filter :set_page_title
  skip_before_filter :load_project

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = t('common.not_allowed')
    redirect_to project_group_path(@project_group)
  end

  def index
    @roles = @project_group.project_group_roles.in_alphabetical_order.all
    @invitations = @project_group.invitations

    respond_to do |f|
      f.any(:html, :m)
      f.xml   { render :xml     => @project_group_roles.to_xml(:root => 'project_group_roles') }
      f.json  { render :as_json => @project_group_roles.to_xml(:root => 'project_group_roles') }
      f.yaml  { render :as_yaml => @project_group_roles.to_xml(:root => 'project_group_roles') }
    end
  end

  def update
    authorize! :update, @project_group_role
    @project_group_role.update_attributes params[:project_group_role]

    respond_to do |wants|
      wants.html {
        if request.xhr?
          render :partial => 'people/person', :locals => {:project => @current_project, :person => @person }
        else
          flash[:success] = t('people.update.success', :name => @project_group_role.user.name)
          redirect_to project_group_role_url(@project_group)
        end
      }
    end
  end

  def destroy
    authorize! :destroy, @project_group_role
    @project_group_role.destroy

    respond_to do |wants|
      wants.html {
        if request.xhr?
          head :ok
        elsif @user == current_user
          flash[:success] = t('deleted.left_project', :name => @user.name)
          redirect_to root_path
        else
          flash[:success] = t('deleted.person', :name => @user.name)
          redirect_to project_group_role_path(@project_group)
        end
      }
    end
  end


  protected

  def load_project_group
    if project_group_id = params[:project_group_id] || params[:id]
      unless @project_group = ProjectGroup.find_by_id_or_permalink(project_group_id)
        flash[:error] = t('not_found.project_group', :id => project_group_id)
        redirect_to project_groups_path
      end
    end
  end

  def load_group_role
    @project_group_role = @project_group.project_group_roles.find params[:id]
    @user = @project_group_role.user
  end
end
