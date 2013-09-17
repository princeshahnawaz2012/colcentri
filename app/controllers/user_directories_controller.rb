class UserDirectoriesController < ApplicationController
  def index
  end

  #Gets the information needed to show the new view
  def new
    @dirId = params[:createdInDir]
  end

  #Gets the information needed to show the rename view (not needed anymore)
  def rename
    allowed = check_user(params[:dirId])
    if (allowed)
      @id = params[:dirId]
      @currentName = UserDirectory.find(params[:dirId]).name
    else
      flash[:error] = t('user_directories.show_content.notAllowedToRename')
      redirect_to user_files_path
    end
  end

  #Gets the information needed to show the show_content view
  def show_content
    @currentDirectory = params[:dirId]
    hasAccess = check_user(params[:dirId])
    if (hasAccess)
      @userDirectories = UserDirectory.find_by_sql(["select * from user_directories where user_id = ? and id != ?",
      current_user.id, params[:dirId]])
      #se crea un UserDirectory nuevo que representa el directorio raíz del usuario
      ud = UserDirectory.new
      ud.id = 0
      ud.name = t('user_directories.changeDirectory.rootDirectory')
      ud.user_id = current_user.id
      @userDirectories.push(ud)
      @userDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
      ud = UserDirectory.find(params[:dirId])
      @dirName = ud.name
      @dirId = ud.id
      @idParentDir = ud.user_directory_id
      @pathDirNames = getPathDirectoryNames(ud, [])
      @pathDirIds = getPathDirectoryIds(ud, [])

      if (params[:order].nil?)
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order(:name)
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order(:asset_file_name)
      elsif (params[:order] == "sizedesc")
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order("size desc")
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("asset_file_size desc")
      elsif (params[:order] == "sizeasc")
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order("size asc")
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("asset_file_size asc")
      elsif (params[:order] == "timeasc")
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order(:name)
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("created_at asc")
      elsif (params[:order] == "timedesc")
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order(:name)
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("created_at desc")
      elsif (params[:order] == "nameasc")
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order("name asc")
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("asset_file_name asc")
      else
        @ownedDirectories = UserDirectory.where(:user_directory_id => params[:dirId]).order("name desc")
        @dirFiles = UserFile.where(:user_directory_id => params[:dirId]).order("asset_file_name desc")
      end
      @links = generateFileLinks(@dirFiles)
    else
      flash[:error] = t('user_directories.show_content.notAllowedToSee')
      redirect_to user_files_path
    end
  end

  #Gets the information needed to show the changeDirectory view(not needed anymore)
  def changeDirectory
    @currentDirectory = UserDirectory.find(params[:dirId]).user_directory_id
    @userDirectories = UserDirectory.find_by_sql(["select * from user_directories where user_id = ? and id != ?",
      current_user.id, params[:dirId]])
    #se crea un UserDirectory nuevo que representa el directorio raíz del usuario
    ud = UserDirectory.new
    ud.id = 0
    ud.name = t('user_directories.changeDirectory.rootDirectory')
    ud.user_id = current_user.id
    @userDirectories.push(ud)
    @userDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
  end

  #Creates a new directory
  def create
    canCreate = true
    if (!params[:dirId].empty?)
      canCreate = check_user(params[:dirId])
    end
    if (canCreate)
      ud = UserDirectory.new
      ud.name = params[:name]
      ud.user_id = current_user.id
      if (!params[:dirId].empty?)
        ud.user_directory_id = params[:dirId]
      end
      ud.save
      if (!params[:dirId].empty?)
        redirect_to show_content_user_directory_path(:dirId => params[:dirId])
      else
        redirect_to user_files_path
      end
    else
      flash[:error] = t('user_directories.create.notAllowedToCreate')
      redirect_to user_files_path
    end
  end

  #Deletes a directory
  def delete
    canDelete = check_user(params[:dirId])
    if (canDelete)
      ud = UserDirectory.find(params[:dirId])
      deleteOwnedFiles(params[:dirId], true)
      if (ud.user_directory_id.nil?) #se borra una carpeta del primer nivel
        redirect_to user_files_path
      else
        redirect_to show_content_user_directory_path(:dirId => ud.user_directory_id)
      end
    else
      flash[:error] = t('user_directories.delete.notAllowedToDelete')
      redirect_to user_files_path
    end
  end

  #Renames a directory(not needed anymore)
  def change_name
    allowed = check_user(params[:dirId])
    if (allowed)
      ud = UserDirectory.find(params[:dirId])
      ud.name = params[:newName]
      ud.save
      if (ud.user_directory_id.nil?) #se renombra una carpeta del primer nivel
        redirect_to user_files_path
      else
        redirect_to show_content_user_directory_path(:dirId => ud.user_directory_id)
      end
    else
      flash[:error] = t('user_directories.show_content.notAllowedToRename')
      redirect_to user_files_path
    end
  end

  #Moves a directory
  #params[:directory] = 0 when we want to move to the root directory
  def moveDirectory
    canMove = check_user(params[:dirId])
    if (params[:directory].to_i != 0)
      canMove = check_user(params[:directory])
    end
    if (canMove)
      ud = UserDirectory.find(params[:dirId])
      if (params[:directory].to_i != 0 and containedInDirectory(params[:directory].to_i, params[:dirId].to_i))
        flash[:error] = t('user_directories.moveDirectory.errorMovingToInnerDirectory')
        if (!ud.user_directory_id.nil?)
          redirect_to show_content_user_directory_path(:dirId => ud.user_directory_id)
        else
          redirect_to user_files_path
        end
      else
        if (!ud.user_directory_id.nil?)
          recalculateDirSizes(ud.user_directory_id, ud.size, '-')
        end
        ud.user_directory_id = params[:directory]
        if (ud.user_directory_id != 0)
          recalculateDirSizes(ud.user_directory_id, ud.size, '+')
        else
          ud.user_directory_id = nil
        end
        ud.save
        if (!params[:currentDirectory].nil? and !params[:currentDirectory].empty?)
          redirect_to show_content_user_directory_path(:dirId => params[:currentDirectory])
        else
          redirect_to user_files_path
        end
      end
    else
      flash[:error] = t('user_directories.moveDirectory.notAllowedToMove')
      redirect_to user_files_path
    end
  end

  private

    #Checks if the current user is the owner of the directory with id = dirId
    def check_user(dirId)
      idDirectoryUser = UserDirectory.find(dirId).user_id
      if (idDirectoryUser == current_user.id)
        return true
      else return false
      end
    end

    #Returns true if the user_directory with id = dirA is contained in the user_directory with id = dirB and false
    #otherwise
    def containedInDirectory(dirA, dirB)
      udId = UserDirectory.find(dirA).user_directory_id
      if (udId.nil?)
        return false
      elsif (udId == dirB)
        return true
      else
        return containedInDirectory(udId, dirB)
      end
    end

    #Deletes all the files in a directory recursively
    def deleteOwnedFiles(dirId, recalculateParentsSize)
      ud = UserDirectory.find(dirId)
      if (recalculateParentsSize and !ud.user_directory_id.nil?)
        recalculateDirSizes(ud.user_directory_id, ud.size, '-')
      end
      ud.destroy
      ownedFiles = UserFile.where(:user_directory_id => dirId)
      for i in 0...ownedFiles.length
        uf = UserFile.find(ownedFiles[i].id)
        #delete the file from Amazon
        establishAmazonS3Connection
        AWS::S3::S3Object.delete('user_files/' + current_user.login + "/" + uf.amazon_id + "/" + uf.asset_file_name,
          ENV['S3_BUCKET'] || 'colcentric-dev2')
        #update the user used storage
        current_user.used_storage -= uf.asset_file_size
        current_user.save(false)
        uf.destroy
      end
      ownedDirectories = UserDirectory.where(:user_directory_id => dirId)
      for i in 0...ownedDirectories.length
        deleteOwnedFiles(ownedDirectories[i].id, false)
      end
    end

    #Generates Amazon S3 links
    def generateFileLinks(files)
      @links = []
      for i in 0...files.length
        @links.push(AWS::S3::S3Object.url_for(
          'user_files/' + current_user.login + "/" + files.at(i).amazon_id + "/" + files.at(i).asset_file_name,
          ENV['S3_BUCKET'] || 'colcentric-dev2', :expires_in => 60 * 60 * 6)) #link expires in 6h
      end
      @links
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
    def recalculateDirSizes(parentDirId, dirSize, op)
      ud = UserDirectory.find(parentDirId)
      if (op == '+')
        ud.size += dirSize
        ud.save
        if (!ud.user_directory_id.nil?)
          recalculateDirSizes(ud.user_directory_id, dirSize, '+')
        end
      else
        ud.size -= dirSize
        ud.save
        if (!ud.user_directory_id.nil?)
          recalculateDirSizes(ud.user_directory_id, dirSize, '-')
        end
      end
    end

    #Gets all the names of the directories in the path of ud, which is the one passed by parameter
    def getPathDirectoryNames(ud, dirNames)
      dirNames.push(ud.name)
      while (!ud.user_directory_id.nil?) do
        ud = UserDirectory.find(ud.user_directory_id)
        dirNames.insert(0, ud.name)
      end
      dirNames
    end

    #Gets all the ids of the directories in the path of ud, which is the one passed by parameter
    def getPathDirectoryIds(ud, dirIds)
      dirIds.push(ud.id)
      while (!ud.user_directory_id.nil?) do
        ud = UserDirectory.find(ud.user_directory_id)
        dirIds.insert(0, ud.id)
      end
      dirIds
    end
end
