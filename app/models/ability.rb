class Ability
  include CanCan::Ability

  def initialize(user)
    
    # Comment & commentable permissions
    
    can :update, Comment do |comment|
      comment.user_id == user.id and
        Time.now < 15.minutes.since(comment.created_at)
    end
    
    can :destroy, Comment do |comment|
      comment.project.admin?(user) or
        ( comment.user_id == user.id and
          Time.now < 15.minutes.since(comment.created_at) )
    end
    
    can :comment, [Task, Conversation] do |object, project|
      project ||= object.project
      project.commentable?(user)
    end
    
    can :watch, [Task, Conversation] do |object|
      object.project.commentable?(user)
    end

    can :see, Task do |task|
      # only for private tasks
      if task.private
        # Shown when not assigned, and also to admins, the creator, and the assigned user
        !task.assigned || task.project.admin?(user) || task.user == user || (task.assigned.user == user)
      else
        true
      end
    end

    can :edit, Task do |task|
      if task.owner?(user)
        true
      elsif task.private?
        task.project.admin?(user)
      else
        task.project.participant?(user)
      end
    end
    
    # Core object permissions
    
    can :update, [Conversation, Task, TaskList, Page, Upload] do |object|
      object.editable?(user)
    end
    
    can :destroy, [Conversation, Task, TaskList, Upload] do |object|
      object.owner?(user) or object.project.admin?(user)
    end

    can :destroy, Page do |object|
      object.editable?(user)
    end

    can :admin, [Conversation, Task, TaskList, Page, Upload] do |object|
      object.owner?(user) or object.project.admin?(user)
    end
    
    # Person permissions
    
    can :update, Person do |person|
      person.project.admin?(user) and !person.project.owner?(person.user)
    end
    
    can :destroy, Person do |person|
      !person.project.owner?(person.user) and (person.user == user or person.project.admin?(user))
    end

    # ProjectGroupRole permissions

    can :update, ProjectGroupRole do |project_group_role|
      project_group_role.project_group.admin?(user) and !project_group_role.project_group.owner?(project_group_role.user)
    end

    can :destroy, ProjectGroupRole do |group_role|
      !group_role.project_group.owner?(group_role.user) and (group_role.user == user or group_role.project_group.admin?(user))
    end
    
    # Invite permissions
    
    can :update, Invitation do |invitation|
      invitation.editable?(user)
    end
    
    can :destroy, Invitation do |invitation|
      invitation.editable?(user)
    end
    
    # Project permissions
    
    can :converse, Project do |project|
      project.commentable?(user)
    end
    
    can :make_tasks, Project do |project|
      project.editable?(user)
    end
    
    can :make_task_lists, Project do |project|
      project.editable?(user)
    end
    
    can :make_pages, Project do |project|
      project.editable?(user)
    end
    
    can :upload_files, Project do |project|
      project.editable?(user)
    end
    
    can :reorder_objects, Project do |project|
      project.editable?(user)
    end
    
    # TODO: remove, this should be consolidated into the organization
    can :transfer, Project do |project|
      project.admin?(user)
    end
    
    can :update, Project do |project|
      project.owner?(user) or project.admin?(user)
    end
    
    can :destroy, Project do |project|
      project.owner?(user)
    end
    
    can :admin, Project do |project|
      project.owner?(user) or project.admin?(user)
    end


    # ProjectGroup permissions

    can :update, ProjectGroup do |pg|
      pg.admin?(user)
    end

    can :destroy, ProjectGroup do |pg|
      pg.owner?(user)
    end

    can :admin, ProjectGroup do |pg|
      pg.admin?(user)
    end

    can :transfer, ProjectGroup do |pg|
      pg.admin?(user)
    end

    # Organization permissions
    
    can :admin, Organization do |organization|
      organization.is_admin?(user)
    end

    can :create, :organization do
      user.super_admin?
    end

    can :see, :organizations do
      user.can_see_admin_menu?
    end

    # User permissions
    
    can :create_project, User do |the_user|
      the_user.can_create_project?
    end
    
    can :admin, User do |the_user|
      user.id == the_user.id
    end
    
    can :observe, User do |the_user|
      user.observable?(the_user)
    end


    # subscription permissions

    can :destroy, Subscription do |subscription|
      (subscription.sponsor_user == user) or ((not subscription.sponsor_user) && subscription.user == user)
    end


    # Report permissions

    can :see, :report do
        user.super_admin?
    end


  end
end
