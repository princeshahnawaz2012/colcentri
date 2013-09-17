class UploadsController < ApplicationController
  before_filter :find_upload, :only => [:destroy,:update,:thumbnail,:show]
  skip_before_filter :load_project, :only => [:download]
  before_filter :set_page_title
  before_filter :check_project_archived, :only => [:index]
  before_filter :check_project_archived_search, :only => [ :search, :searchResults, :new ]

  SEND_FILE_METHOD = :default

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |f|
      error_message = "You are not allowed to do that!"
      f.js             { render :text => "alert('#{error_message}')" }
      f.any(:html, :m) { render :text => "alert('#{error_message}')" }
    end
  end

#same as upload_directories_controller
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


  def check_project_archived_search
    begin
      @current_project = Project.find(params[:currentProjectId])
    rescue
      @current_project = -1
    end


    if @current_project.archived? and not @current_project == -1
      if @current_project.user_id != current_user.id
        flash[:error] = t('errors.projects.archived')
        redirect_to show_all_project_groups_path(:archived_projects => false)
      else
        redirect_to project_settings_path(@current_project.permalink)
      end
    end
  end


  #Gets the information needed to show the index view
  def index
    @permission = check_user(@current_project.id)
    if (@permission == 1 or @permission == 2)
      @uploadDirectories = UploadDirectory.where(:project_id => @current_project.id).order(:name)
      ud = UploadDirectory.new
      ud.id = nil
      ud.name = t('uploads.changeDirectory.rootDirectory')
      ud.project_id = @current_project.id
      ud.user_id = current_user.id
      @uploadDirectories.push(ud)
      @uploadDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase } #bug
      if (params[:order].nil?)
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:name)
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:asset_file_name)
      elsif (params[:order] == 'sizedesc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order("size desc")
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("asset_file_size desc")
      elsif (params[:order] == 'sizeasc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order("size asc")
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("asset_file_size asc")
      elsif (params[:order] == 'timedesc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:name)
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("created_at desc")
      elsif (params[:order] == 'timeasc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:name)
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("created_at asc")
      elsif (params[:order] == 'authordesc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:name)
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil)
        @uploads.sort! { |a,b| b.user.login.downcase <=> a.user.login.downcase }
      elsif (params[:order] == 'authorasc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order(:name)
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil)
        @uploads.sort! { |a,b| a.user.login.downcase <=> b.user.login.downcase }
      elsif (params[:order] == 'namedesc')
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order("name desc")
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("asset_file_name desc")
      else
        @directories = UploadDirectory.where(:project_id => @current_project.id, :upload_directory_id => nil).order("name asc")
        @uploads = Upload.where(:project_id => @current_project.id, :upload_directory_id => nil).order("asset_file_name asc")
      end
      @upload ||= @current_project.uploads.new
    else
      flash[:error] = t('uploads.index.notAllowedToShow')
      redirect_to projects_path
    end
  end

  def show
    redirect_to @upload.url
  end


  #Gets the information needed to upload a file to Amazon S3
  def new
    if (check_user(params[:currentProjectId]) == 1)
      @fileIdInAmazon = Time.now.strftime("%d-%m-%Y_%H:%M:%S") + "*" + current_user.login
      @directory = "assets/" + @fileIdInAmazon + "/original" + "/${filename}"
      projectAdminId = Project.find(params[:currentProjectId]).user_id
      @availableStorage = Colcentric.config.storage - User.find(projectAdminId).used_storage
      #local hack @availableStorage = 1000 - User.find(projectAdminId).used_storage


      options = {}
      bucket = ENV['S3_BUCKET'] || 'colcentric-dev2'
      @access_key_id = "AKIAJWK6BWS3M3MIWTPQ"
      secret_access_key = "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"

      options[:acl] = 'private'
      options[:expiration_date] = 2.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
      options[:max_filesize] = 10000.megabytes

      @policy = Base64.encode64(
        "{'expiration': '#{options[:expiration_date]}',
          'conditions': [
            {'bucket': '#{bucket}'},
            {'acl': '#{options[:acl]}'},
            ['starts-with', '$success_action_redirect', ''],
            ['starts-with', '$Content-Type', ''],
            ['starts-with', '$Content-Disposition', ''],
            ['content-length-range', 0, #{options[:max_filesize]}],
            ['starts-with', '$key', 'assets/']
          ]
        }").gsub(/\n|\r/, '')

      @signature = Base64.encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'),
        secret_access_key, @policy)).gsub("\n","")
    else
      flash[:error] = t('uploads.create.notAllowedToCreate')
      redirect_to projects_path
    end
  end



  #Creates a new file both in the DB and Amazon S3 and updates the used storage of the project admin
  def create
    if (check_user(params[:currentProjectId]) == 1)
      fileAmazonId = params[:key].split("/")[1]
      fileName = params[:key].split("/")[3]
      establishAmazonS3Connection
      file = AWS::S3::S3Object.find 'assets/' + fileAmazonId + '/original/' + fileName, ENV['S3_BUCKET'] || 'colcentric-dev2'
      #if the user exceeds the maximum storage provided, we delete the file in Amazon
      projectAdminId = Project.find(params[:currentProjectId]).user_id
      if (User.find(projectAdminId).used_storage + file.size > Colcentric.config.storage)
      #if (User.find(projectAdminId).used_storage + file.size > 100000) #hack for local testing of file uploads

        AWS::S3::S3Object.delete('assets/' +  fileAmazonId + '/original/' + fileName, ENV['S3_BUCKET'] || 'colcentric-dev2')
        flash[:error] = t('uploads.create.maximumStorageExceeded')
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      else
        u = Upload.new
        u.user_id = current_user.id
        u.project_id = params[:currentProjectId]
        u.asset_file_name = fileName
        u.asset_file_size = file.size
        u.amazon_id = fileAmazonId
        if (!params[:uploadedInDir].nil?)
          u.upload_directory_id = params[:uploadedInDir]
          recalculateUploadDirSizes(params[:uploadedInDir], u.asset_file_size, '+')
        end
        u.save
        #redirect
        if (!params[:uploadedInDir].nil?)
          redirect_to show_content_upload_directory_path(:uploadDirId => params[:uploadedInDir],
            :currentProjectId => params[:currentProjectId])
        else
          redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
        end
      end
    else
      flash[:error] = t('uploads.create.notAllowedToCreate')
      redirect_to projects_path
    end
  end


  #Moves a file
  def moveFile
    if (check_user(params[:currentProjectId]) == 1)
      u = Upload.find(params[:uploadId])
      currentDirectory = u.upload_directory_id
      if (!currentDirectory.nil?)
        recalculateUploadDirSizes(currentDirectory, u.asset_file_size, '-')
      end
      if (params[:directory].nil? or params[:directory].empty? or params[:directory] == "")
        u.upload_directory_id = nil
      else
        u.upload_directory_id = params[:directory]
        recalculateUploadDirSizes(u.upload_directory_id, u.asset_file_size, '+')
      end
      u.save
      if (!currentDirectory.nil?)
        redirect_to show_content_upload_directory_path(:uploadDirId => currentDirectory,
          :currentProjectId => params[:currentProjectId])
      else
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      end
    else
      flash[:error] = t('uploads.moveFile.notAllowedToMove')
      redirect_to projects_path
    end
  end

  #Renames an uploaded file
  def change_name
    if (check_user(params[:currentProjectId]) == 1)
      u = Upload.find(params[:uploadId])
      if (u.asset_file_name != params[:newName])
        establishAmazonS3Connection
        AWS::S3::S3Object.rename('assets/' + (u.amazon_id || u.id.to_s) + '/original/' + u.asset_file_name,
          'assets/' + (u.amazon_id  || u.id.to_s) + '/original/' + params[:newName], ENV['S3_BUCKET'] || 'colcentric-dev2')
        u.asset_file_name = params[:newName]
        u.save
      end
      if (u.upload_directory_id.nil?)
       redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      else
       redirect_to show_content_upload_directory_path(:uploadDirId => u.upload_directory_id,
          :currentProjectId => params[:currentProjectId])
      end
    else
      flash[:error] = t('uploads.changeName.notAllowedToRename')
      redirect_to projects_path
    end
  end

  #Deletes an uploaded file and updates the used storage of the project admin
  def delete
    if (check_user(params[:currentProjectId]) == 1)
      u = Upload.find(params[:uploadId])
      if (!u.upload_directory_id.nil?)
        recalculateUploadDirSizes(u.upload_directory_id, u.asset_file_size, '-')
      end
      establishAmazonS3Connection
      AWS::S3::S3Object.delete('assets/' + (u.amazon_id || u.id.to_s) + '/original/' + u.asset_file_name,
        ENV['S3_BUCKET'] || 'colcentric-dev2')
      u.deleted = true
      u.save
      #update the used storage of the project admin
      projectAdmin = User.find(Project.find(params[:currentProjectId]).user_id)
      projectAdmin.used_storage -= u.asset_file_size
      projectAdmin.save(false)
      #redirect
      if (u.upload_directory_id.nil?)
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      else
        redirect_to show_content_upload_directory_path(:uploadDirId => u.upload_directory_id,
          :currentProjectId => params[:currentProjectId])
      end
    else
      flash[:error] = t('uploads.delete.notAllowedToDelete')
      redirect_to projects_path
    end
  end

  def update
    authorize! :update, @upload
    @upload.update_attributes(params[:upload])

    respond_to do |format|
      format.js   { render :layout => false }
      format.any(:html, :m)  { redirect_to project_uploads_path(@current_project) }
    end
  end

  def destroy
    authorize! :destroy, @upload
    @slot_id = @upload.page_slot.try(:id)
    @upload.try(:destroy)

    respond_to do |f|
      f.js   { render :layout => false }
      f.any(:html, :m) do
        flash[:success] = t('deleted.upload', :name => @upload.to_s)
        redirect_to project_uploads_path(@current_project)
      end
    end
  end

  def search
    @permission = check_user(params[:currentProjectId])
    if (@permission == 1 or @permission == 2)
      @currentProjectId = params[:currentProjectId]
      @projectCreationDate = Project.find(@currentProjectId).created_at
    else
      flash[:error] = t('uploads.search.notAllowedToSearch')
      redirect_to projects_path
    end
  end

  def searchResults
    @permission = check_user(params[:currentProjectId])
    start_time = Time.utc(params["date"]["year"], params["date"]["month"], params["date"]["day"],
      params["date"]["hour"], params["date"]["minute"])
    minSize = 0
    maxSize = Colcentric.config.storage
    minSize = params[:minSize].to_i * 1024 * 1024 if !params[:minSize].empty?
    maxSize = params[:maxSize].to_i * 1024 * 1024 if !params[:maxSize].empty?
    @files = Upload.find_by_sql(["select * from uploads where project_id = ? and asset_file_size >= ?
      and asset_file_size <= ? and deleted = false", params[:currentProjectId], minSize, maxSize])
    if (!params[:name].empty?)
      files_aux = []
      @files.each do |f|
        if (params[:aproxSearch])
          files_aux.push(f) if f.nameWithoutExtension.downcase.include? params[:name].downcase
        else
          files_aux.push(f) if f.nameWithoutExtension.downcase == params[:name].downcase
        end
      end
      @files = files_aux
    end
    if (!params[:extension].empty?)
      files_aux = []
      @files.each do |f|
        files_aux.push(f) if f.extension.downcase == params[:extension].downcase
      end
      @files = files_aux
    end
    if (!params[:author].empty?)
      files_aux = []
      @files.each do |f|
        files_aux.push(f) if f.user.login.downcase == params[:author].downcase
      end
      @files = files_aux
    end
    files_aux = []
    @files.each do |f|
      files_aux.push(f) if f.created_at >= start_time
    end
    @files = files_aux
  end

  private

    def find_upload
      if params[:id].to_s.match /^\d+$/
        @upload = @current_project.uploads.find(params[:id])
      else
        @upload = @current_project.uploads.find_by_asset_file_name(params[:id])
      end
    end

    #returns 1 if the current user is participating in the project with id = projectId with the role admin/participant
    #returns 2 if the current user is participating in the project with id = projectId with a different role
    #returns 3 if the current user is not participating in the project with id = projectId
    def check_user(projectId)
      p = Person.where(:project_id => projectId)
      p.each do |person|
        if (person.user_id == current_user.id)
          if (person.role == 2 or person.role == 3)
            return 1
          else
            return 2
          end
        end
      end
      return 3
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

    #Recalculates the size of the directory with id = parentDirId
    def recalculateUploadDirSizes(parentDirId, fileSize, op)
      ud = UploadDirectory.find(parentDirId)
      if (op == '+')
        ud.size += fileSize
        ud.save
        if (!ud.upload_directory_id.nil?)
          recalculateUploadDirSizes(ud.upload_directory_id, fileSize, '+')
        end
      else
        ud.size -= fileSize
        ud.save
        if (!ud.upload_directory_id.nil?)
          recalculateUploadDirSizes(ud.upload_directory_id, fileSize, '-')
        end
      end
    end



















































=begin #Old version
  def new
    authorize! :upload_files, @current_project
    @upload = @current_project.uploads.new
    @upload.user = current_user
  end
=end

=begin #Old version
  def create
    authorize! :upload_files, @current_project
    authorize! :update, @page if @page
    @upload = @current_project.uploads.new params[:upload]
    @upload.user = current_user
    @page = @upload.page
    calculate_position(@upload) if @page

    @upload.save

    respond_to do |wants|
      wants.any(:html, :m) {
        if @upload.new_record?
          flash.now[:error] = "There was an error uploading the file"
          render :new
        elsif @upload.page
          if iframe?
            code = render_to_string 'create.js.rjs', :layout => false
            render :template => 'shared/iframe_rjs', :layout => false, :locals => { :code => code }
          else
            redirect_to [@current_project, @upload.page]
          end
        else
          redirect_to [@current_project, :uploads]
        end
      }
    end
  end
=end


=begin Old version
  def download
    head(:not_found) and return if (upload = Upload.find_by_id(params[:id])).nil?
    head(:forbidden) and return unless upload.downloadable?(current_user)

    path = upload.asset.path(params[:style])
    unless File.exist?(path) && params[:filename].to_s == upload.asset_file_name
      head(:bad_request)
      raise "Unable to download file"
    end

    mime_type = File.mime_type?(upload.asset_file_name)

    mime_type = 'application/octet-stream' if mime_type == 'unknown/unknown'

    send_file_options = { :type => mime_type }

    response.headers['Cache-Control'] = 'private, max-age=31557600'

    case SEND_FILE_METHOD
      when :apache then send_file_options[:x_sendfile] = true
      when :nginx then head(:x_accel_redirect => path.gsub(Rails.root, ''), :content_type => send_file_options[:type]) and return
    end

    send_file(path, send_file_options)
  end
=end

  #Gets the information needed to show the rename view(not used anymore)
  def rename
    if (check_user(params[:currentProjectId]) == 1)
      @currentProjectId = params[:currentProjectId]
      @uploadId = params[:uploadId]
      @currentName = Upload.find(params[:uploadId]).asset_file_name
    else
      flash[:error] = t('uploads.changeName.notAllowedToRename')
      redirect_to projects_path
    end
  end

  #Gets the information needed to show the changeDirectory view (not used anymore)
  def changeDirectory
    if (check_user(params[:currentProjectId]) == 1)
      @currentProjectId = params[:currentProjectId]
      @uploadId = params[:uploadId]
      @uploadDirectories = UploadDirectory.where(:project_id => params[:currentProjectId])
      ud = UploadDirectory.new
      ud.id = nil
      ud.name = t('uploads.changeDirectory.rootDirectory')
      ud.project_id = params[:currentProjectId]
      ud.user_id = current_user.id
      @uploadDirectories.push(ud)
      @uploadDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    else
      flash[:error] = t('uploads.changeDirectory.notAllowedToMove')
      redirect_to projects_path
    end
  end


end
