module UploadsHelper
  
  def upload_primer(project)
    render 'uploads/primer', :project => project
  end
  
  def link_to_upload(upload, text, attributes = {})
    if (!upload.deleted)
      link_to(h(text), upload.url)
    else text
    end
  end
  
  def upload_link_with_thumbnail(upload)
    if (!upload.deleted)
      link_to image_tag(upload.url(:thumb, false, '/thumb/')),
        upload.url,
        :class => 'link_to_upload', :rel => 'facebox'
    else
      upload.asset_file_name
    end
  end

  def page_upload_actions_link(page, upload)
    if current_user && can?(:update, upload)
      render 'uploads/slot_actions', :upload => upload, :page => page
    end
  end
  
  def list_uploads_inline(uploads)
    render :partial => 'uploads/file', :collection => uploads, :as => :upload
  end

  def list_uploads_inline_with_thumbnails(uploads)
    render :partial => 'uploads/thumbnail', :collection => uploads, :as => :upload
  end

  def file_icon_image(upload,size='48px')
    unless upload.file_name.nil?
      extension = File.extname(upload.file_name)
      if extension.length > 0
        extension = extension[1,10]
      end

      if Upload::ICONS.include?(extension)
        image_tag("file_icons/#{size}/#{extension}.png", :class => "file_icon #{extension}")
      else
        image_tag("file_icons/#{size}/_blank.png")
      end
    end
  end

  def formatAvailableStorage(bytes)
    size = bytes/1024
    if (size <= 0)
      size = "0 MB"
    elsif (size >= 1024)
      size = (size/1024).to_s + "MB"
    else
      size = size.to_s + "KB"
    end
  end



end
