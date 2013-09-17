require 'digest/sha1'

# A User model describes an actual user, with his password and personal info.
# A Person model describes the relationship of a User that follows a Project.

class User < ActiveRecord::Base
  include Immortal
  include Metadata
  extend Metadata::Defaults





  include Rails.application.routes.url_helpers

  concerned_with  :activation,
                  :avatar,
                  :authentication,
                  :conversions,
                  :recent_projects,
                  :roles,
                  :rss,
                  :scopes,
                  :validation,
                  :task_reminders

  has_many :projects_owned, :class_name => 'Project', :foreign_key => 'user_id'
  has_many :comments
  has_many :conversations
  has_many :task_lists
  has_many :pages
  has_many :people
  has_many :project_group_roles
  has_many :projects, :through => :people, :order => 'name ASC'
  has_many :invitations, :foreign_key => 'invited_user_id'
  has_many :activities
  has_many :uploads
  has_many :app_links, :dependent => :destroy
  has_many :memberships
  has_many :colcentric_datas
  has_many :project_group_roles
  has_many :project_groups, :through => :project_group_roles, :order => 'name ASC'
  has_one  :subscription
  has_many :videoconference_subscriptions, :foreign_key => 'user_id'
  has_many :sponsor_subscriptions, :class_name => 'Subscription', :foreign_key => 'sponsor_user_id'
  has_many :invoices
  has_one  :shopping_cart
  has_many :user_files
  has_many :user_directories
  has_many :videoconferences
  has_many :participations, :class_name => 'Participant', :foreign_key => 'user_id'
  has_many :drafts, :class_name => "Message", :conditions => {:sent => false, :deleted => false}
  has_many :sent_messages, :class_name => "Message", :foreign_key => "user_id",  :conditions => {:sent => true, :deleted=> false}
  has_many :received_messages, :class_name => "MessageCopy", :foreign_key => "recipient_id", :conditions => {:deleted => false}
  has_many :organizations, :through => :memberships
  has_many :admin_organizations, :through => :memberships, :source => :organization, :conditions => {'memberships.role' => Membership::ROLES[:admin]}
  has_many :forms
  has_many :formular_answers, :class_name => 'Form'

  belongs_to :invited_by, :class_name => 'User'


  has_one :card
  accepts_nested_attributes_for :card
  default_scope :order => 'users.updated_at DESC'
  scope :in_alphabetical_order, :order => 'users.first_name ASC'

  attr_accessible :id,
                  :confirmed_user,
                  :invited_by_id,
                  :created_at,
                  :updated_at,
                  :deleted,
                  :login,
                  :email,
                  :first_name,
                  :last_name,
                  :biography,
                  :password,
                  :password_confirmation,
                  :old_password,
                  :time_zone,
                  :locale,
                  :first_day_of_week,
                  :betatester,
                  :card_attributes,
                  :notify_conversations,
                  :notify_tasks,
                  :splash_screen,
                  :wants_task_reminder,
                  :company_name,
                  :country,
                  :phone,
                  :comercial_code,
                  :terms_of_use,
                  :accept_terms,
                  :invoices,
                  :videoconferences,
                  :videoconference_subscription,
                  :sent_message


  attr_accessor   :activate, :old_password

  before_validation :sanitize_name
  before_destroy :rename_as_deleted
  
  before_create :init_user
  #before_create :build_folders
  after_create :clear_invites  #Send the activation e-mail after create the new user
  after_create :trial_subscription
  before_save :update_token

  def num_videoconferences
    videoconference_subscriptions.count
  end

 def update_token
    self.recent_projects_ids ||= []
    self.rss_token ||= generate_rss_token
    self.visited_at ||= Time.now
  end

  def init_user
    if invitation = Invitation.find_by_email(email)
      self.invited_by = invitation.user
      invitation.user.update_attribute :invited_count, (invitation.user.invited_count + 1)
    end
    self.card ||= build_card
    self.splash_screen = true
  end

  def clear_invites
    send_activation_email unless self.confirmed_user

    if invitations = Invitation.find_all_by_email(email)
      for invitation in invitations
        invitation.accept(self)
        invitation.destroy
      end
    end
  end

  def trial_subscription
    @subscription = self.build_subscription
    @subscription.status = 0
    @subscription.licence_type = 1
    @subscription.trial_expiration_date = Time.now + 15.day
    @subscription.save
  end

  def self.find_by_username_or_email(login)
    return unless login
    if login.include? '@' # usernames are not allowed to contain '@'
      find_by_email(login.downcase)
    else
      find_by_login(login.downcase)
    end
  end

  def to_s
    #name
    login
  end

  def to_param
    login_was # in case it changes but is not yet saved
  end

  def visited_at
    read_attribute(:visited_at) || updated_at
  end
  
  def locale
    if I18n.available_locales.map(&:to_s).include? self[:locale]
      self[:locale]
    else
      I18n.default_locale.to_s
    end
  end

  def projects_shared_with(user)
    self.projects & user.projects
  end

  def organizations_shared_with(user)
    self.organizations & user.organizations
  end

  def shares_invited_projects_with?(user)
    Invitation.count(:conditions => {:project_id => user.project_ids, :invited_user_id => self.id}) > 0
  end
  
  def users_with_shared_projects
    ids = self.projects.map(&:user_ids).flatten
    ids += Invitation.find(:all, :conditions => {:project_id => self.project_ids}, :select => 'user_id').map(&:user_id)
    
    User.find(:all, :conditions => {:id => ids.uniq})
  end

  def new_comment(user,target,comment)
    self.comments.new(comment) do |comment|
      comment.user_id = user.id
      comment.target = target
    end
  end

  def log_activity(target, action, creator_id=nil)
    creator_id ||= target.user_id
    Activity.log(nil, target, action, creator_id)
  end

  def update_visited_at
    if visited_at.nil? or (Time.now - visited_at) >= 12.hours
      update_attribute(:visited_at, Time.now)
    end
  end
  
  def person_for(project)
    self.people.find_by_project_id(project.id)
  end
  
  def member_for(organization)
    self.memberships.find_by_organization_id(organization.id)
  end
  
  def watching?(object)
    object.has_watcher? self
  end

  def utc_offset
    @utc_offset ||= ActiveSupport::TimeZone[time_zone].try(:utc_offset) || 0
  end
  
  def in_project(project)
    project.people.find_by_user_id(self)
  end

  def contacts
    conditions = ["project_id IN (?)", Array(self.projects).collect{ |p| p.id } ]
    user_ids = Person.find(:all,
      :select => 'user_id',
      :conditions => conditions,
      :limit => 300).collect { |p| p.user_id }.uniq
    conditions = ["id IN (?) AND deleted = ? AND id != (?)", user_ids, false, self.id]
    User.find(:all,
      :conditions => conditions,
      :order => 'updated_at DESC',
      :limit => 60)
  end

  def active_projects_count
    projects.unarchived.count
  end

  def can_create_project?
    Colcentric.config.community || self.memberships.where("role > 15").exists?
    #true
  end

  def can_see_admin_menu?
    if Colcentric.config.community
      super_admin? | (memberships.admin?.count > 0)
    else
      super_admin? | (memberships.admin?.count > 0) | (memberships.participant?.count > 0)
    end
  end

  def count_free_sponsorized_subscriptions?
    sponsor_subscriptions.active.unassigned.count
  end

  def get_free_sponsorized_subscription
    sponsor_subscriptions.active.unassigned.first
  end

  DELETED_TAG = "deleted"
  DELETED_REGEX = /#{DELETED_TAG}\d+__(.*)/i

  def rename_as_deleted
    tag = find_available_deleted_tag
    update_attribute :login, "#{tag}#{login}" unless login =~ DELETED_REGEX
    update_attribute :email, "#{tag}#{email}" unless email =~ DELETED_REGEX
  end

  def rename_as_active
    login =~ DELETED_REGEX
    update_attribute :login, Regexp.last_match(1).to_s if login =~ DELETED_REGEX
    update_attribute :email, Regexp.last_match(1).to_s if email =~ DELETED_REGEX
  end

  def link_to_app(provider, uid, credentials)
    link = AppLink.new
    link.user              = self
    link.provider          = provider
    link.app_user_id       = uid
    link.access_token      = credentials ? credentials[:token] : nil
    link.access_secret     = credentials ? credentials[:secret] : nil
    link.save!
  end



  def self.find_available_login(proposed_login = nil)
    proposed_login ||= "user"
    counter = 0
    begin
      counter += 1
      login = "#{proposed_login}#{counter == 1 ? nil : counter}"
    end while User.find_with_deleted(:first, :conditions => ["login LIKE ?", login])
    login
  end

  def active_project_ids
    @active_project_ids ||= Person.where(:user_id => id).joins(:project).where(:projects => { :archived => false }).collect(&:id)
  end

  def pending_tasks
    Rails.cache.fetch("pending_tasks.#{id}") do
      active_project_ids.empty? ? [] :
        Task.where(:status => Task::ACTIVE_STATUS_CODES).where(:assigned_id => active_project_ids).order('ID desc').includes(:project).
             sort { |a,b| (a.due_on || 1.week.from_now.to_date) <=> (b.due_on || 1.year.from_now.to_date) }
    end
  end

  def clear_pending_tasks!
    Rails.cache.delete("pending_tasks.#{id}")
  end

  def tasks_counts_update
    assigned_tasks = Task.assigned_to(self)
    # we do t.statys && t.status < 3 because some tasks might be 
    self.assigned_tasks_count  = assigned_tasks.select { |t| t.status == 1 }.length
    self.completed_tasks_count = assigned_tasks.select { |t| t.status == 3 }.length
    self.save
  end

  def users_for_user_map
    @users_for_user_map ||= self.organizations.map{|o| o.users + o.users_in_projects }.flatten.uniq
  end

  def has_paid_license?
      (self.subscription.active?) and (self.subscription.paid? or self.subscription.special?)
  end

  def clear_invoices
     invoices.each do |i|
       if i.status == Invoice::STATUS[:Incomplete]
         i.destroy
       end
     end
  end

  def future_participations?
    if participations
      participations.each do |p|
        return true if Time.now < p.videoconference.start_time
      end
    else
      return false
    end
  end

  def has_videoconference_subscription?

    videoconference_subscriptions.where( :status => VideoconferenceSubscription::STATUS[:Active]).count > 0
    #videoconference_subscription and videoconference_subscription.is_active?
  end

  protected

    def find_available_deleted_tag
      counter = 0
      begin
        counter += 1
        tag = "#{DELETED_TAG}#{counter}__"
        user = User.find_with_deleted(:first,
                :conditions => "login LIKE '#{tag}#{login}' OR email LIKE '#{tag}#{email}'")
      end while user
      tag
    end

    def sanitize_name
      self.first_name = first_name.blank?? nil : first_name.squish
      self.last_name = last_name.blank?? nil : last_name.squish
    end



end
