module ProjectGroupRolesHelper
  def leave_project_group_link(project_group)
    unless project_group.user == current_user
      link_to t('people.column.leave_project'),
        project_group_project_group_role_path(project_group.id, current_user.project_group_roles.detect { |p| p.project_group_id == project_group.id }),
        :method => :delete, :confirm => t('people.column.confirm_delete'), :class => :leave_link
    end
  end

  def options_for_project_groups(project_groups)
    project_groups.sort_by(&:name).collect { |o| [o.name, o.id ]}
  end


  def options_for_new_project(user_id)
    project_groups = []
    project_groups_list = []

    current_user.people.each do |p|
      project = Project.find(p.project_id)
      if not project_groups_list.include?(project.project_group_id) and not project.archived?
        project_groups_list.push(project.project_group_id)
        begin
          project_group = ProjectGroup.find(project.project_group_id) if project.project_group_id
        rescue Exception => exec
          project_groups_list.delete(project.project_group_id)
          logger.error(exec)
        end

        project_groups.push([project_group.name, project_group.id]) if project_group
      end

    end

    current_user.project_groups.each do |p|
      if not project_groups_list.include?(p.id)
        project_groups_list.push(p.id)
        project_groups.push([p.name, p.id])
      end
    end

    project_groups.sort
  end



end
