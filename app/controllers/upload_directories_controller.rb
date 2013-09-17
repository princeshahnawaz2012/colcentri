class UploadDirectoriesController < ApplicationController

  before_filter :check_project_archived, :only => [ :show_content ]

  def check_project_archived
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


  #Gets the information needed to show the new view
  def new
    if (check_permission(params[:currentProjectId], "create") == 1)
      @currentProjectId = params[:currentProjectId]
      @uploadDirId = params[:createdInDir]
    else
      flash[:error] = t('user_directories.create.notAllowedToCreate')
      redirect_to projects_path
    end
  end



  #Gets the information needed to show the show_content view
  def show_content
    @current_project_id = params[:currentProjectId]
    @currentDirectory = params[:uploadDirId]
    @permission = check_permission(params[:currentProjectId], "show_content")
    if (@permission == 1 or @permission == 2)
      @uploadDirectories = UploadDirectory.where(:project_id => @current_project_id).order(:name)
      ud = UploadDirectory.new
      ud.id = nil
      ud.name = t('uploads.changeDirectory.rootDirectory')
      ud.project_id = @current_project_id
      ud.user_id = current_user.id
      @uploadDirectories.push(ud)
      @uploadDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
      ud = UploadDirectory.find(params[:uploadDirId])
      p = Project.find(params[:currentProjectId])
      @currentProjectName = p.permalink
      @currentProjectId = p.id
      @uploadDirName = ud.name
      @uploadDirId = ud.id
      @idParentDir = ud.upload_directory_id
      @pathDirNames = getPathDirectoryNames(ud, [])
      @pathDirIds = getPathDirectoryIds(ud, [])
      if (params[:order].nil?)
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order(:name)
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order(:asset_file_name)
      elsif (params[:order] == 'sizedesc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order("size desc")
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("asset_file_size desc")
      elsif (params[:order] == 'sizeasc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order("size asc")
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("asset_file_size asc")
      elsif (params[:order] == 'timedesc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order(:name)
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("created_at desc")
      elsif (params[:order] == 'timeasc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order(:name)
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("created_at asc")
      elsif (params[:order] == 'authordesc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order(:name)
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("user_id desc")
      elsif (params[:order] == 'authorasc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order(:name)
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("user_id asc")
      elsif (params[:order] == 'namedesc')
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order("name desc")
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("asset_file_name desc")
      else
        @ownedDirectories = UploadDirectory.where(:upload_directory_id => params[:uploadDirId]).order("name asc")
        @uploads = Upload.where(:upload_directory_id => params[:uploadDirId]).order("asset_file_name asc")
      end
    else
      flash[:error] = t('upload_directories.show_content.notAllowedToSee')
      redirect_to projects_path
    end
  end


  #Creates a new upload directory
  def create
    if (check_permission(params[:currentProjectId], "create") == 1)
      ud = UploadDirectory.new
      ud.name = params[:name]
      ud.project_id = params[:currentProjectId]
      ud.user_id = current_user.id
      ud.size = 0
      if (!params[:uploadDirId].empty?)
        ud.upload_directory_id = params[:uploadDirId]
      end
      ud.save
      if (!params[:uploadDirId].empty?)
        redirect_to show_content_upload_directory_path(:uploadDirId => params[:uploadDirId],
          :currentProjectId => params[:currentProjectId])
      else
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      end
    else
      flash[:error] = t('upload_directories.create.notAllowedToCreate')
      redirect_to projects_path
    end
  end

  #Renames an upload directory
  def changeName
    if (check_permission(params[:currentProjectId], "changeName") == 1)
      ud = UploadDirectory.find(params[:uploadDirId])
      ud.name = params[:newName]
      ud.save
      if (ud.upload_directory_id.nil?)
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      else
        redirect_to show_content_upload_directory_path(:uploadDirId => ud.upload_directory_id,
          :currentProjectId => params[:currentProjectId])
      end
    else
      flash[:error] = t('upload_directories.changeName.notAllowedToRename')
      redirect_to projects_path
    end
  end

  #Deletes an upload directory
  def delete
    if (check_permission(params[:currentProjectId], "delete") == 1)
      ud = UploadDirectory.find(params[:uploadDirId])
      projectAdmin = User.find(Project.find(params[:currentProjectId]).user_id)
      deleteOwnedUploads(params[:uploadDirId], true, projectAdmin)
      if (ud.upload_directory_id.nil?)
        redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
      else
        redirect_to show_content_upload_directory_path(:uploadDirId => ud.upload_directory_id,
          :currentProjectId => params[:currentProjectId])
      end
    else
      flash[:error] = t('upload_directories.delete.notAllowedToDelete')
      redirect_to projects_path
    end
  end

  #Moves a directory
  #params[:directory] = 0 when we want to move to the root directory
  def moveDirectory
    if (check_permission(params[:currentProjectId], "moveDirectory") == 1)
      ud = UploadDirectory.find(params[:uploadDirId])
      if (params[:directory].to_i != 0 and containedInDirectory(params[:directory].to_i, params[:uploadDirId].to_i))
        flash[:error] = t('upload_directories.moveDirectory.errorMovingToInnerDirectory')
        if (!ud.upload_directory_id.nil?)
          redirect_to show_content_upload_directory_path(:uploadDirId => ud.upload_directory_id,
            :currentProjectId => params[:currentProjectId])
        else
          redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
        end
      else
        aux = nil
        if (!ud.upload_directory_id.nil?)
          aux = ud.upload_directory_id
          recalculateUploadDirSizes(ud.upload_directory_id, ud.size, '-')
        end
        ud.upload_directory_id = params[:directory]
        if (ud.upload_directory_id != 0)
          recalculateUploadDirSizes(ud.upload_directory_id, ud.size, '+')
        else
          ud.upload_directory_id = nil
        end
        ud.save
        if(!aux.nil?)
          redirect_to show_content_upload_directory_path(:uploadDirId => aux,
            :currentProjectId => params[:currentProjectId])
        else
          redirect_to project_uploads_path(Project.find(params[:currentProjectId]).permalink)
        end
      end
    else
      flash[:error] = t('upload_directories.moveDirectory.notAllowedToMove')
      redirect_to projects_path
    end
  end

  private

    #returns 1 if the current user is participating in the project with id = projectId with the role admin/participant
    #returns 2 if the current user is participating in the project with id = projectId with a different role
    #returns 3 if the current user is not participating in the project with id = projectId
    def check_permission(projectId, op)
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

    #Deletes all the uploaded files in an upload directory recursively and updates the used storage of the project admin
    def deleteOwnedUploads(uploadDirId, recalculateParentsSize, projectAdmin)
      ud = UploadDirectory.find(uploadDirId)
      if (recalculateParentsSize and !ud.upload_directory_id.nil?)
        recalculateUploadDirSizes(ud.upload_directory_id, ud.size, '-')
      end
      ud.destroy
      ownedUploads = Upload.where(:upload_directory_id => uploadDirId)
      for i in 0...ownedUploads.length
        u = Upload.find(ownedUploads[i].id)
        establishAmazonS3Connection
        AWS::S3::S3Object.delete('assets/' + (ownedUploads[i].amazon_id || ownedUploads[i].id.to_s) + '/original/' + ownedUploads[i].asset_file_name,
          ENV['S3_BUCKET'] || 'colcentric-dev2')
        u.deleted = true
        u.save
        #update the used storage of the project admin
        projectAdmin.used_storage -= u.asset_file_size
        projectAdmin.save(false)
      end
      ownedUploadDirectories = UploadDirectory.where(:upload_directory_id => uploadDirId)
      for i in 0...ownedUploadDirectories.length
        deleteOwnedUploads(ownedUploadDirectories[i].id, false, projectAdmin)
      end
    end

    #Returns true if the user_directory with id = dirA is contained in the user_directory with id = dirB and false
    #otherwise
    def containedInDirectory(dirA, dirB)
      udId = UploadDirectory.find(dirA).upload_directory_id
      if (udId.nil?)
        return false
      elsif (udId == dirB)
        return true
      else
        return containedInDirectory(udId, dirB)
      end
    end

    #Recalculates the size of the directory with id = parentDirId
    def recalculateUploadDirSizes(parentDirId, dirSize, op)
      ud = UploadDirectory.find(parentDirId)
      if (op == '+')
        ud.size += dirSize
        ud.save
        if (!ud.upload_directory_id.nil?)
          recalculateUploadDirSizes(ud.upload_directory_id, dirSize, '+')
        end
      else
        ud.size -= dirSize
        ud.save
        if (!ud.upload_directory_id.nil?)
          recalculateUploadDirSizes(ud.upload_directory_id, dirSize, '-')
        end
      end
    end

    #Gets all the names of the upload directories in the path of ud, which is the one passed by parameter
    def getPathDirectoryNames(ud, dirNames)
      dirNames.push(ud.name)
      while (!ud.upload_directory_id.nil?) do
        ud = UploadDirectory.find(ud.upload_directory_id)
        dirNames.insert(0, ud.name)
      end
      dirNames
    end

    #Gets all the ids of the uploads directories in the path of ud, which is the one passed by parameter
    def getPathDirectoryIds(ud, dirIds)
      dirIds.push(ud.id)
      while (!ud.upload_directory_id.nil?) do
        ud = UploadDirectory.find(ud.upload_directory_id)
        dirIds.insert(0, ud.id)
      end
      dirIds
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

   #Gets the information needed to show the rename view (not needed anymore)
  def rename
    if (check_permission(params[:currentProjectId], "changeName") == 1)
      @currentProjectId = params[:currentProjectId]
      @id = params[:uploadDirId]
      @currentName = UploadDirectory.find(params[:uploadDirId]).name
    else
      flash[:error] = t('user_directories.rename.notAllowedToRename')
      redirect_to projects_path
    end
  end


  #Gets the information needed to show the changeDirectory view (not needed anymore)
  def changeDirectory
    if (check_permission(params[:currentProjectId], "moveDirectory") == 1)
      @currentProjectId = params[:currentProjectId]
      @uploadDirectories = UploadDirectory.find_by_sql(["select * from upload_directories where project_id = ? and id != ?",
        params[:currentProjectId], params[:uploadDirId]])
      ud = UploadDirectory.new
      ud.id = 0
      ud.name = t('upload_directories.changeDirectory.rootDirectory')
      ud.project_id = params[:currentProjectId]
      ud.user_id = current_user.id
      @uploadDirectories.push(ud)
      @uploadDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    else
      flash[:error] = t("upload_directories.changeDirectory.notAllowedToMove")
      redirect_to projects_path
    end
  end
end