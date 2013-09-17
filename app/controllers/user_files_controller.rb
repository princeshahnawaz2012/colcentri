require 'base64'
require 'openssl'
require 'digest/sha1'

class UserFilesController < ApplicationController

  before_filter :find_user

  #Gets the information needed to show the index of the user files view
  def index
    @userDirectories = UserDirectory.where(:user_id => current_user.id).order(:name)
    #A new UserDirectory representing the root directory is created
    ud = UserDirectory.new
    ud.id = nil
    ud.name = t('user_files.changeDirectory.rootDirectory')
    ud.user_id = current_user.id
    @userDirectories.push(ud)
    @userDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    @files = []
    @directories = []
    @simpleView = params[:simpleView]
    if (params[:order].nil?)
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order(:asset_file_name)
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order(:asset_file_name)
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order(:name)
      end
    elsif (params[:order] == "sizedesc")
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("asset_file_size desc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("asset_file_size desc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order("size desc") unless params[:simpleView]
      end
    elsif (params[:order] == "sizeasc")
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("asset_file_size asc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("asset_file_size asc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order("size asc") unless params[:simpleView]
      end
    elsif (params[:order] == "timedesc")
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("created_at desc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("created_at desc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order(:name) unless params[:simpleView]
      end
    elsif (params[:order] == "timeasc")
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("created_at asc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("created_at asc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order(:name) unless params[:simpleView]
      end
    elsif (params[:order] == "namedesc")
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("asset_file_name desc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("asset_file_name desc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order("name desc") unless params[:simpleView]
      end
    else
      if (@simpleView)
        @files = UserFile.where(:user_id => current_user.id).order("asset_file_name asc")
      else
        @files = UserFile.where(:user_id => current_user.id, :user_directory_id => nil).order("asset_file_name asc")
        @directories = UserDirectory.where(:user_id => current_user.id, :user_directory_id => nil).order("name asc") unless params[:simpleView]
      end
    end
    @links = generateFileLinks(@files)
  end

  def show
  end

  #Gets the information needed to show the changeDirectory view
  def changeDirectory
    @currentDirectory = UserFile.find(params[:fileId]).user_directory_id
    @userDirectories = UserDirectory.where(:user_id => current_user.id).order(:name)
    #A new UserDirectory representing the root directory is created
    ud = UserDirectory.new
    ud.id = nil
    ud.name = t('user_files.changeDirectory.rootDirectory')
    ud.user_id = current_user.id
    @userDirectories.push(ud)
    @userDirectories.sort! { |a,b| a.name.downcase <=> b.name.downcase }
  end

  #Gets the information needed to upload a file to Amazon S3
  def new
    @fileIdInAmazon = Time.now.strftime("%d-%m-%Y_%H:%M:%S")
    @directory = "user_files/" + current_user.login + "/"+ @fileIdInAmazon + "/${filename}"
    @simpleView = params[:simpleView]
    @availableStorage = Colcentric.config.storage - current_user.used_storage

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
          ['starts-with', '$key', 'user_files/']
        ]
      }").gsub(/\n|\r/, '')

    @signature = Base64.encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'),
      secret_access_key, @policy)).gsub("\n","")
  end

  #Gets the information needed to show the rename view(not needed anymore)
  def rename
    @fileId = params[:fileId]
    @currentName = UserFile.find(params[:fileId]).asset_file_name
    @simpleView = params[:simpleView]
  end

  #deletes a file both from the DB and Amazon S3 and updates the user used storage
  def delete
    canDelete = check_user(params[:fileId])
    if (canDelete)
      uf = UserFile.find(params[:fileId])
      udId = uf.user_directory_id
      if (!udId.nil?)
        recalculateDirSizes(udId, uf.asset_file_size, '-')
      end
      establishAmazonS3Connection
      AWS::S3::S3Object.delete('user_files/' + current_user.login + '/' + uf.amazon_id + '/' + uf.asset_file_name,
        ENV['S3_BUCKET'] || 'colcentric-dev2')
      #update the user used storage
      current_user.used_storage -= uf.asset_file_size
      current_user.save(false)
      uf.destroy
      #redirect
      if (params[:simpleView])
         redirect_to user_files_path(:simpleView => true)
      elsif (!udId.nil?)
        redirect_to show_content_user_directory_path(:dirId => udId)
      else
        redirect_to user_files_path
      end
    else
      flash[:error] = t('user_files.delete.notAllowedToDelete')
      redirect_to user_files_path
    end
  end

  #Creates a new file both in the DB and Amazon S3 and updates the user used storage
  def create
    canCreate = true
    if (!params[:uploadedInDir].nil?)
      canCreate = check_user_dir(params[:uploadedInDir])
    end
    if (canCreate)
      #key is a param received from Amazon
      fileAmazonId = params[:key].split("/")[2]
      fileName = params[:key].split("/")[3]
      #create the file in Amazon S3
      establishAmazonS3Connection
      file = AWS::S3::S3Object.find 'user_files/' + current_user.login + '/' + fileAmazonId + '/' + fileName,
        ENV['S3_BUCKET'] || 'colcentric-dev2'
      #if the user exceeds the maximum storage provided, we delete the file in Amazon
      if (current_user.used_storage + file.size > Colcentric.config.storage)
        AWS::S3::S3Object.delete('user_files/' + current_user.login + '/' + fileAmazonId + '/' + fileName,
          ENV['S3_BUCKET'] || 'colcentric-dev2')
        flash[:error] = t('user_files.create.maximumStorageExceeded')
        redirect_to user_files_path
      else
        #create the file in the DB
        uf = UserFile.new
        uf.user_id = current_user.id
        uf.asset_file_name = params[:key].split("/")[3]
        uf.asset_file_size = file.size
        uf.amazon_id = fileAmazonId
        if (!params[:uploadedInDir].nil?)
          uf.user_directory_id = params[:uploadedInDir]
          recalculateDirSizes(params[:uploadedInDir], uf.asset_file_size, '+')
        end
        uf.save
        #update the user used storage
        current_user.used_storage += uf.asset_file_size
        current_user.save(false)
        #redirect the user
        if (!params[:uploadedInDir].nil?)
          redirect_to show_content_user_directory_path(:dirId => params[:uploadedInDir])
        elsif (params[:simpleView])
          redirect_to user_files_path(:simpleView => true)
        else
          redirect_to user_files_path
        end
      end
    else
      flash[:error] = t('user_files.create.notAllowedToCreate')
      redirect_to user_files_path
    end
  end

  #Moves a file
  def moveFile
    canMove = check_user(params[:fileId])
    if (!params[:directory].empty?)
      canMove = check_user_dir(params[:directory])
    end
    if (canMove)
      uf = UserFile.find(params[:fileId])
      if (!uf.user_directory_id.nil?)
        recalculateDirSizes(uf.user_directory_id, uf.asset_file_size, '-')
      end
      if (params[:directory].nil? or params[:directory].empty? or params[:directory] == "" or params[:directory].to_i == 0)
        uf.user_directory_id = nil
      else
        uf.user_directory_id = params[:directory]
        recalculateDirSizes(uf.user_directory_id, uf.asset_file_size, '+')
      end
      uf.save
      if (!params[:currentDirectory].nil? and !params[:currentDirectory].empty?)
        redirect_to show_content_user_directory_path(:dirId => params[:currentDirectory])
      else
        redirect_to user_files_path
      end
    else
      flash[:error] = t('user_files.moveFile.notAllowedToMove')
      redirect_to user_files_path
    end
  end

  #Changes the name of a file both in the DB and Amazon S3
  def change_name
    if (check_user(params[:fileId]))
      uf = UserFile.find(params[:fileId])
      if (uf.asset_file_name != params[:newName])
        establishAmazonS3Connection
        AWS::S3::S3Object.rename('user_files/' + current_user.login + "/" + uf.amazon_id + "/" + uf.asset_file_name,
          'user_files/' + current_user.login + "/" + uf.amazon_id + "/" + params[:newName], ENV['S3_BUCKET'] || 'colcentric-dev2')
        uf.asset_file_name = params[:newName]
        uf.save
      end
      if (params[:simpleView])
        redirect_to user_files_path(:simpleView => true)
      elsif (uf.user_directory_id.nil?) #The file we are trying to rename is located in the root directory
        redirect_to user_files_path
      else
        redirect_to show_content_user_directory_path(:dirId => uf.user_directory_id)
      end
    else
      flash[:error] = t('user_directories.show_content.notAllowedToRename')
      redirect_to user_files_path
    end
  end

  def search
    @userRegistrationDate = current_user.created_at
  end

  def searchResults
    start_day = params["date"]["day"]
    start_month = params["date"]["month"]
    start_year = params["date"]["year"]
    start_hour = params["date"]["hour"]
    start_minute = params["date"]["minute"]
    start_time = Time.utc(start_year, start_month, start_day, start_hour, start_minute)
    minSize = 0
    maxSize = Colcentric.config.storage
    minSize = params[:minSize].to_i * 1024 * 1024 if !params[:minSize].empty?
    maxSize = params[:maxSize].to_i * 1024 * 1024 if !params[:maxSize].empty?
    @files = UserFile.find_by_sql(["select * from user_files where user_id = ? and asset_file_size >= ?
      and asset_file_size <= ?", current_user.id, minSize, maxSize])
    if (!params['name'].empty?)
      files_aux = []
      @files.each do |f|
        if (params['aproxSearch'])
          files_aux.push(f) if f.nameWithoutExtension.downcase.include? params['name'].downcase
        else
          files_aux.push(f) if f.nameWithoutExtension.downcase == params['name'].downcase
        end

      end
      @files = files_aux
    end
    if (!params['extension'].empty?)
      files_aux = []
      @files.each do |f|
        files_aux.push(f) if f.extension.downcase == params['extension'].downcase
      end
      @files = files_aux
    end
    files_aux = []
    @files.each do |f|
      files_aux.push(f) if f.created_at >= start_time
    end
    @files = files_aux
    @links = generateFileLinks(@files)
  end

  private
    #Gets the current user
    def find_user
      unless @user = ( User.find_by_login(current_user.login) || User.find_by_id(current_user.id) )
        flash[:error] = t('not_found.user')
        redirect_to root_path
      end
    end

    #Checks if the current user is the owner of the file with id = fileId
    def check_user(fileId)
      idFileUser = UserFile.find(fileId).user_id
      if (idFileUser == current_user.id)
        return true
      else return false
      end
    end

    #Checks if the current user is the owner of the directory with id = dirId
    def check_user_dir(dirId)
      return true if dirId.to_i == 0
      idUserDir = UserDirectory.find(dirId).user_id
      if (idUserDir == current_user.id)
        return true
      else return false
      end

    end

    #Links to Amazon S3 are generated
    def generateFileLinks(files)
      @links = []
      establishAmazonS3Connection
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
    def recalculateDirSizes(parentDirId, fileSize, op)
      ud = UserDirectory.find(parentDirId)
      if (op == '+')
        ud.size += fileSize
        ud.save
        if (!ud.user_directory_id.nil?)
          recalculateDirSizes(ud.user_directory_id, fileSize, '+')
        end
      else
        ud.size -= fileSize
        ud.save
        if (!ud.user_directory_id.nil?)
          recalculateDirSizes(ud.user_directory_id, fileSize, '-')
        end
      end
    end
end