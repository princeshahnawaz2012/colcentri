class Upload < RoleRecord
  include Immortal

  ICONS = %w(aac ai aiff avi bmp c cpp css dat dmg doc dotx dwg dxf eps exe flv gif h hpp html ics iso java jpg key mid mp3 mp4 mpg odf ods odt otp ots ott pdf php png ppt psd py qt rar rb rtf sql tga tgz tiff txt wav xls xlsx xml yml zip)
    
  belongs_to :user
  belongs_to :comment, :touch => true, :counter_cache => true
  belongs_to :project
  belongs_to :page

  has_one        :page_slot, :as => :rel_object
  before_destroy :clear_slot
  before_destroy :update_comment_to_show_delete
  after_destroy  :cleanup_activities
  after_destroy  :free_used_storage

  before_create :copy_ownership_from_comment
  after_create  :log_create

  after_create :update_used_storage

  attr_accessible :asset,
                  :page_id,
                  :description
                  :id
                  :user_id
                  :project_id
                  :description
                  :asset_file_name
                  :asset_file_size
                  :amazon_id
  
  include PageWidget

  has_attached_file :asset,
    :styles => { :thumb => "150x150>" },
    :url  => "/assets/:id/:style/:basename.:extension",
    :path => Colcentric.config.amazon_s3 ?
      "assets/:id/:style/:filename" :
      ":rails_root/assets/:id/:style/:filename",
    :s3_permissions => 'private',
    :s3_headers => {'Cache-Control' => 'max-age=157680000'}

  before_post_process :image?

=begin #Old
  validates_attachment_size :asset, 
                            :less_than => Colcentric.config.asset_max_file_size.to_i.megabytes,
                            :message => I18n.t('uploads.form.max_size', 
                                               :mb => Colcentric.config.asset_max_file_size.to_i)
=end

  validates_attachment_presence :asset, :message => I18n.t('uploads.form.presence')

  validate :check_page

  def check_page
    if page && (page.project_id != project_id)
      @errors.add :project, 'is not valid'
    end
  end
  
  def image?
    !(asset_content_type =~ /^image.*/).nil?
  end

  def url(style_name = nil, use_timestamp = false, folder = '/original/')
=begin   **Old version
    if !!Colcentric.config.amazon_s3
      AWS::S3::S3Object.url_for(asset.path(style_name), asset.bucket_name, {:expires_in => Colcentric.config.amazon_s3_expiration.to_i})
    else
      asset.url(style_name, use_timestamp)
    end
=end
    establishAmazonS3Connection
    #Files uploaded as comments attachments don't have an amazon_id, their id is used instead
    AWS::S3::S3Object.url_for('assets/' + (amazon_id || id.to_s) + folder + asset_file_name,
    ENV['S3_BUCKET'] || 'colcentric-dev2', :expires_in => 60 * 60 * 6)

  end

  def file_name
    asset_file_name
  end

  def size
    asset_file_size
  end

  # TODO: handle truncating of description in views
  include ActionView::Helpers::TextHelper

  def description
    self[:description] || (comment ? truncate(comment.body, :length => 80) : nil)
  end
  
  def slot_view
    'uploads/upload_slot'
  end

  def log_create
    save_slot if page
    project.log_activity(self, 'create', user_id) unless comment
  end

  def cleanup_activities
    unless self.comment
      Activity.destroy_all :target_type => self.class.name, :target_id => self.id
    end
  end
  
  def to_s
    file_name
  end

  def downloadable?(user)
    true
  end

  def file_type
    ext = File.extname(file_name).sub('.','')
    ext = '...' if ext == ''
    ext
  end
  
  def user
    @user ||= user_id ? User.with_deleted.find_by_id(user_id) : nil
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.file :id => id do
      xml.tag! 'page-id', page_id
      xml.tag! 'filename', asset_file_name
      xml.tag! 'description', description
      xml.tag! 'mime-type', asset_content_type
      xml.tag! 'bytes', asset_file_size
      xml.tag! 'download', url
      xml.tag! 'created-at', created_at.to_s(:db)
      xml.tag! 'updated-at', updated_at.to_s(:db)
      xml.tag! 'user-id', user_id
      xml.tag! 'comment-id', comment_id
    end
  end
  
  def to_api_hash(options = {})
    base = {
      :id => id,
      :page_id => page_id,
      :slot_id => page_slot ? page_slot.id : nil,
      :filename => asset_file_name,
      :description => description,
      :mime_type => asset_content_type,
      :bytes => asset_file_size,
      :download => url,
      :created_at => created_at.to_s(:api_time),
      :updated_at => updated_at.to_s(:api_time),
      :user_id => user_id,
      :comment_id => comment_id
    }
    
    base[:type] = self.class.to_s if options[:emit_type]
    
    base
  end

  def extension
    splitName = asset_file_name.split('.')
    if (splitName.size < 2)
      return ""
    else
      return splitName[-1]
    end
  end

  def nameWithoutExtension
    splitName = asset_file_name.split('.')
    name = ""
    for i in 0...splitName.length - 1
      name.concat(splitName[i])
      name.concat('.') if i != splitName.length - 2
    end
    name
  end

  #adds the size of the created file to the used space of the project admin of the project where the file was uploaded
  def update_used_storage
    projectAdmin = User.find(Project.find(project_id).user_id)
    projectAdmin.used_storage += asset_file_size
    projectAdmin.save(false)
  end

  def free_used_storage
    projectAdmin = User.find(Project.find(project_id).user_id)
    projectAdmin.used_storage -= asset_file_size
    projectAdmin.save(false)
  end

  def short_name
    short = []
    for i in 0...16
      short.push(asset_file_name[i].chr)
    end
    short.push('...')
    short
  end

  private
    #Establishes a connection with Amazon S3
    def establishAmazonS3Connection
      unless AWS::S3::Base.connected?
      AWS::S3::Base.establish_connection!(
        :access_key_id =>  ENV['S3_KEY'],
        :secret_access_key => ENV['S3_SECRET']
      )
      end
    end

  protected
  def copy_ownership_from_comment
    if comment_id
      self.user_id = comment.user_id
      self.project_id = comment.project_id
    end
  end
  
  def update_comment_to_show_delete
    if self.comment && self.comment.body.blank? && self.comment.uploads.count == 1
      self.comment.update_attributes(:body => "File deleted")
    end
  end
end
