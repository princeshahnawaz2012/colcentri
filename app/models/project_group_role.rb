class ProjectGroupRole < ActiveRecord::Base
  ROLES = {:admin => 20}
  
  belongs_to :user
  belongs_to :project_group

  scope :admin?, :conditions => {'memberships.role' => ROLES[:admin]}

  scope :in_alphabetical_order, :include => :user, :order => 'users.first_name ASC'

  def role_name
    ROLES.index(role)
  end

  def owner?
    project_group.owner?(user)
  end

  def to_s
    name
  end

  def name
    user.name
  end
end
