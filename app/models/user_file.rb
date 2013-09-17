class UserFile < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_directory

  validates_presence_of :user_id, :asset_file_name, :asset_file_size

  attr_accessible  :id,
                  :user_id,
                  :asset_file_name,
                  :asset_file_size,
                  :created_at,
                  :updated_at

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

  def short_name
    short = []
    for i in 0...16
      short.push(asset_file_name[i].chr)
    end
    short.push('...')
    short
  end

end
