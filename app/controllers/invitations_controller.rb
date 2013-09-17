class InvitationsController < ApplicationController
  skip_before_filter :load_project
  before_filter :load_target, :except => [:invite_format]
  before_filter :set_page_title
  before_filter :load_user_invitation, :only => [ :accept, :decline ]
  skip_before_filter :belongs_to_project?, :only => [ :accept, :decline ]
  
  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |f|
      message = t('common.not_allowed')
      f.html {
        flash[:error] = message
        redirect_to project_path(@current_project)
      }
      f.js { render :text => "alert('#{message}')" }
    end
  end
  
  def index
    if @invite_target
      if @invite_target.has_member?(current_user)
        @invited_to_project = false
      else
        # Do we have an invite?
        @invitation = @invite_target.invitations.find(:first, :conditions => {:invited_user_id => current_user.id})
        if @invitation.nil?
          render :text => "You don't have permission to view this project", :status => :forbidden
          return
        end
      end
      
      respond_to do |f|
        f.any(:html, :m) {
          if @invitation
            render :action => 'index_project'
          elsif @invite_target.is_a? Project
            redirect_to project_people_path(@current_project)
          elsif @invite_target.is_a? Organization
            redirect_to organization_membership_path(@organization)
          elsif @invite_target.is_a? ProjectGroup
            redirect_to project_group_edit_path(@project_group)
          end }
      end
    else
      @invitations = current_user.invitations.pending_projects
      respond_to do |f|
        f.any(:html, :m) { render :action => 'index_user' }
      end
    end
  end

  def new
    authorize! :admin, @invite_target
    @invitation = @invite_target.invitations.new(:role => role)
    
    respond_to do |f|
      f.any(:html, :m)
    end
  end
  
  def create
    authorize! :admin, @invite_target
    if params[:invitation]
      user_or_email = params[:invitation][:user_or_email]
      if @invite_target.is_a? Project
        params[:invitation][:role] ||= Person::ROLES[:participant]
      end
      if Colcentric.config.community # && !(@invite_target.is_a? Organization)
        params[:invitation][:membership] = Membership::ROLES[:participant]
      end
      # external means not added to the organization at all
      params[:invitation][:membership] ||= Membership::ROLES[:external]
      
=begin
      @targets = user_or_email.extract_emails
      @targets = user_or_email.split if @targets.empty?
=end

      @targets = user_or_email.split( /, */ )

      @invitations = @targets.map { |target| make_invitation(target, params[:invitation], params[:sponsor]) }
    else
      flash[:error] = t('invitations.errors.invalid')
      redirect_to target_people_path
      return
    end
    
    respond_to do |f|
      if @invitations and @saved_count.to_i > 0
        f.any(:html, :m) { redirect_to target_people_path }
      else
        #@message = @invitations.length == 1 ? @invitations.first.errors.full_messages.first :
         #                                    t('people.errors.users_or_emails')
        @message = "tadam"
        f.any(:html, :m) { flash[:error] = "tudum"; redirect_to target_people_path}#message; redirect_to target_people_path }
      end
    end
  end
  
  def resend
    authorize! :admin, @invite_target
    @invitation = Invitation.find_by_id params[:id]
    @invitation.send(:send_email)
    
    respond_to do |wants|
      wants.any(:html, :m) {
        flash[:notice] = t('invitations.resend.resent', :recipient => @invitation.email)
        if @invitation.target.is_a? Project
          redirect_to project_people_path(@invitation.project)
        elsif @invitation.target.is_a? Organization
          redirect_to organization_memberships_path(@invitation.organization)
        elsif @invitation.target.is_a? ProjectGroup
          redirect_to project_group_project_group_roles_path(@invitation.target)
        else
          redirect_back_or_to root_path
        end
      }
      wants.js
    end
  end
  
  def destroy
    @invitation = Invitation.find_by_id params[:id]
    authorize! :destroy, @invitation

    @invitation.destroy

    if request.xhr?
      head :ok
    else
      redirect_back_or_to root_path
    end
  end
  
  def accept
    @invitation.accept(current_user)
    @invitation.destroy
    if @invitation.target.is_a? Project
      redirect_to project_path(@invitation.project)
    elsif @invitation.target.is_a? Organization
      redirect_to organization_path(@invitation.organization)
    elsif @invitation.target.is_a? ProjectGroup
      redirect_to project_group_path(@invitation.project_group)
    end
  end
  
  def decline
    @invitation.destroy
    redirect_to(user_invitations_path(current_user))
  end
  
  def invite_format
    render :layout => false
  end
  
  private
    def load_target
      if params[:project_id]
        load_project
      elsif params[:organization_id]
        @organization = Organization.find_by_id_or_permalink(params[:organization_id])
      elsif params[:project_group_id]
        @project_group = ProjectGroup.find_by_id_or_permalink(params[:project_group_id])
      end

      @invite_target = target
    end
    
    def load_user_invitation
      conds = { :project_id => @current_project.id,
                :invited_user_id => current_user.id }
      
      @invitation = Invitation.find(:first,:conditions => conds)
      unless @invitation
        flash[:error] = t('invitations.errors.invalid_code')
        redirect_to user_invitations_path(current_user)
      end
    end
    
    def target
      @current_project || @project_group || @organization # Order is important. Target may be something & @organization
    end
    
    def target_people_path
      if @invite_target.is_a? Project
        project_people_path(@current_project)
      elsif @invite_target.is_a? Organization
        organization_memberships_path(@organization)
      elsif @invite_target.is_a? ProjectGroup
        project_group_project_group_roles_path(@project_group)
      end
    end
    
    def make_invitation(user_or_email, params, sponsor)
      invitation = @invite_target.invitations.new(params.merge({:user_or_email => user_or_email.strip}))
      invitation.user = current_user

      if sponsor
        subscription = current_user.get_free_sponsorized_subscription
        invitation.subscription = subscription # = nil if there isn't any free
      end

      @saved_count ||= 0
      @saved_count += 1 if invitation.save
      invitation
    end

end
