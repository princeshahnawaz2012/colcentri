module PeopleHelper

  def edit_role_link
     link_to_function t('people.link.edit'), show_edit_role_fields, :class => 'button'
  end

  def show_edit_role_fields
     update_page do |page|
        page['persona'].show
      end
  end


  def options_from_person_roles
    Person::ROLES.map { |role, value| [t("people.fields.#{role}_html"), value] }.sort_by(&:last)
  end

  def options_from_organization_roles
    roles = Membership::ROLES.map { |role, value| [t("memberships.roles.#{role}"), value] }.sort_by(&:last)
    # delete external as they aren't in the organization
    roles.delete_at(0)
    roles
  end
  
  def options_from_other_projects(projects)
    ("<option value=''>#{t('people.column.select_project')}</option>" +
      options_from_collection_for_select(projects, :id, :name)).html_safe
  end

  def options_for_projects_by_organization(commentable_projects)
    commentable_projects.group_by(&:organization).collect do |org,projects|
      "<optgroup label='#{h(org)}'>" +
        options_from_collection_for_select(projects, :id, :name) +
      "</optgroup>"
    end.join.html_safe
  end

  def options_for_projects_by_group(commentable_projects)
    commentable_projects.group_by(&:project_group).collect do |pg,projects|
      "<optgroup label='#{h(pg)}'>" +
        options_from_collection_for_select(projects, :id, :name) +
      "</optgroup>"
    end.join.html_safe
  end

  def options_for_projects_by_one_group(commentable_projects)
    commentable_projects.group_by(&:project_group).collect do |pg,projects|

        options_from_collection_for_select(projects, :id, :name)

    end.join.html_safe
  end

end
