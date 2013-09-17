class ProjectGroup < ActiveRecord::Base
  has_many :projects
  has_many :project_group_roles, :dependent => :destroy
  has_many :invitations

  has_many :users, :through => :project_group_roles

  belongs_to :user
  belongs_to :organization

  with_options :dependent => :delete_all do |delete|
    delete.has_many :invitations
  end

  concerned_with :permalink

  validates_presence_of :user         # A project_group _needs_ an owner
  validates_presence_of :organization

  validates_length_of :name, :minimum => 5, :on => :create  # New projects
  validates_length_of :name, :minimum => 5, :on => :update, :if => :name_changed?  # Changing the name
  validates_uniqueness_of :permalink, :case_sensitive => false
  validates_length_of :permalink, :minimum => 5
  validates_format_of :permalink, :with => /^[a-z0-9_\-]{5,}$/, :if => :permalink_length_valid?


  attr_accessible :name, :permalink, :organization_attributes, :organization_id


  def permalink_length_valid?
    permalink.length >= 5
  end


  def add_project(proj)
    proj.project_group = self
  end

  def remove_project(proj)
    proj.project_group = nil
  end

  def has_member?(user)
    project_group_roles.exists?(:user_id => user.id)
  end

  def add_user(user, params={})
    unless has_member?(user)
      pg_role = ProjectGroupRole.where(:project_group_id => self.id, :user_id => user.id).first
      pg_role ||= project_group_roles.build

      pg_role.user = user
      pg_role.role = params[:role] if params[:role]
      pg_role.save
      pg_role
    end
  end

  def remove_user(user)
    proyect_group_roles.find_by_user_id(user.id).try(:destroy)
  end

  def transfer_to(role)
    self.user = role.user
    saved = self.save
    role.update_attribute(:role, ProjectGroupRole::ROLES[:admin]) if saved # owners need to be admin!
    saved
  end

  def delete_current_owner


  end

  def self.find_by_id_or_permalink(param)
    if param.to_s =~ /^\d+$/
      find_by_id(param)
    else
      find_by_permalink(param)
    end
  end

  def to_s
    name
  end

  def class_name # for translations
    'project_group'
  end

  def to_param
    permalink
  end

  def admin?(user)
    self.project_group_roles.find_by_user_id(user.id) ? true : false
  end

  def owner?(u)
    user == u
  end

  def owner_name
    pgr = ProjectGroupRole.where(:project_group_id => id, :role => 20).first
    User.find(pgr.user_id).login
  end

  def user_participates(user_id)
    if user_id == user_id
      return true
    else
      projects.each do |p|
        return true if Person.where(:user_id => user.id, :project_id => p.id).count > 0
      end
    end
    return false
  end

end
