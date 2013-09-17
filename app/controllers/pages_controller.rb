class PagesController < ApplicationController
  before_filter :load_page, :only => [ :show, :edit, :update, :reorder, :destroy ]
  before_filter :set_page_title
  before_filter :check_project_archived, :only => [:index]

  rescue_from CanCan::AccessDenied do |exception|
    handle_cancan_error(exception)
  end

  def check_project_archived
    if @current_project.archived?
      if @current_project.user_id != current_user.id
        flash[:error] = t('errors.projects.archived')
        redirect_to show_all_project_groups_path(:archived_projects => false)
      else
        redirect_to project_settings_path(@current_project.permalink)
      end
    end
  end

  def index
    if @current_project
      @pages = @current_project.pages
    else
      @pages = current_user.projects.collect { |p| p.pages }
    end
    
    respond_to do |f|
      f.any(:html, :m)
      f.xml { render :xml    => @pages.to_xml(:include => :slots, :root => 'pages') }
      f.json{ render :as_json => @pages.to_xml(:include => :slots, :root => 'pages') }
      f.yaml{ render :as_yaml => @pages.to_xml(:include => :slots, :root => 'pages') }
      f.rss { render :layout => false }
    end
  end
  
  def new
    authorize! :make_pages, @current_project
    @page = Page.new
    
    respond_to do |f|
      f.any(:html, :m)
    end
  end
  
  def create
    authorize! :make_pages, @current_project
    @page = @current_project.new_page(current_user,params[:page])    
    respond_to do |f|
      if @page.save
        f.any(:html, :m) { redirect_to project_page_path(@current_project,@page) }
        handle_api_success(f, @page, true)
      else
        f.any(:html, :m) { render :new }
        handle_api_error(f, @page)
      end
    end
  end
    
  def show
    @pages = @current_project.pages
    
    respond_to do |f|
      f.any(:html, :m)
      f.xml { render :xml    => @page.to_xml(:include => [:slots, :objects]) }
      f.json{ render :as_json => @page.to_xml(:include => [:slots, :objects]) }
      f.yaml{ render :as_yaml => @page.to_xml(:include => [:slots, :objects]) }
    end
  end
  
  def edit
    authorize! :update, @page
    respond_to do |f|
      f.html
      f.m   {
        @edit_part = params[:edit_part]
        if @edit_part == 'page'
          render :show
        else
          render :edit
        end
      }
    end
  end
  
  def update
    authorize! :update, @page
    respond_to do |f|
      if @page.update_attributes(params[:page])
        f.any(:html, :m)  { redirect_to project_page_path(@current_project,@page) }
        handle_api_success(f, @page)
      else
        f.any(:html, :m)  { render :edit }
        handle_api_error(f, @page)
      end
    end
  end
  
  def reorder
    authorize! :update, @page
    order = params[:slots].collect { |id| id.to_i }
    current = @page.slots.map { |slot| slot.id }

    # Handle orphaned elements
    # [1,3,4,5o (4),6o (5),7,8]
    # 1,4,3,8,7 NEW
    # << 1,4,3,8,7
    # insert 1,4,|5|,|6|,3,8,7
    orphans = (current - order).map { |o|
      idx = current.index(o)
      oid = idx == 0 ? -1 : current[idx-1]
      [@page.slots[idx], oid]
    }

    # Insert orphans back into order list
    orphans.each { |o| order.insert(o[1], (order.index(o[0]) || -1)+1) }

    @page.slots.each do |slot|
      slot.position = order.index(slot.id)
      slot.save!
    end

    respond_to do |f|
      f.js   { render :layout => false }
      handle_api_success(f, @page)
    end
  end
  
  def resort
    authorize! :reorder_objects, @current_project
    order = params[:pages].map(&:to_i)
    
    @current_project.pages.each do |page|
      page.suppress_activity = true
      page.position = order.index(page.id)
      page.save
    end
    
    respond_to do |f|
      f.js { render :reorder, :layout => false }
    end
  end

  def destroy
    if can? :destroy, @page
      @page.try(:destroy)

      respond_to do |f|
        flash[:success] = t('deleted.page', :name => @page.to_s)
        f.any(:html, :m)  { redirect_to project_pages_path(@current_project) }
        handle_api_success(f, @page)
      end
    else
      respond_to do |f|
        flash[:error] = t('common.not_allowed')
        f.any(:html, :m) { redirect_to project_page_path(@current_project,@page) }
        handle_api_error(f, @page)
      end
    end
  end

  def upload_file
    projectAdminId = Project.find(params['project_id']).user_id
    if (User.find(projectAdminId).used_storage + params['file'].size > Colcentric.config.storage)
      flash[:error] = t('uploads.create.maximumStorageExceeded')
      redirect_to project_page_path(Project.find(params['project_id']).permalink, Page.find(params['page_id']).permalink)
    else
      establishAmazonS3Connection
      u = Upload.new
      u.user_id = current_user.id
      u.project_id = params['project_id'].to_i
      u.page_id = params['page_id'].to_i
      u.asset_file_name = params['file'].original_filename
      u.asset_file_size = params['file'].size
      u.save
      AWS::S3::S3Object.store("assets/" + u.id.to_s + "/original/" + params['file'].original_filename, params['file'].read, ENV['S3_BUCKET'] || 'colcentric-dev2')
      u.update_used_storage
      redirect_to project_page_path(Project.find(params['project_id']).permalink, Page.find(params['page_id']).permalink)
    end
  end

  private
    def load_page
      page_id = params[:id]
      @page = @current_project.pages.find_by_permalink(page_id) || @current_project.pages.find_by_id(page_id)
      
      unless @page
        flash[:error] = t('not_found.page', :id => page_id)
        redirect_to project_path(@current_project)
      end
    end

    #Establishes a connection with Amazon S3
    def establishAmazonS3Connection
      unless AWS::S3::Base.connected?
        AWS::S3::Base.establish_connection!(
          :access_key_id => ENV['S3_KEY'],
          :secret_access_key => ENV['S3_SECRET']
        )
      end
    end
    
end