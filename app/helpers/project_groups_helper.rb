module ProjectGroupsHelper

  def jsProjectGroupFormValidation
    javascript_tag <<-EOS
      function validate_project_group_name(form) {
        var res = true;

        var project_group_name = form.project_group_name.value;

        if (project_group_name.length > 30){
          res = false;
          form.project_group_name.up(0).setAttribute("class", "field_with_errors");
          Element.show('project_group_error_max_length');
          Element.hide('project_group_error_no_length');
        }else if (project_group_name.length < 5){
          res = false;
          form.project_group_name.up(0).setAttribute("class", "field_with_errors");
          Element.show('project_group_error_no_length');
          Element.hide('project_group_error_max_length');
        }else{
          Element.hide('project_group_error_max_length');
          Element.hide('project_group_error_no_length');
        }

        return res;
    }

    EOS
  end

  def jsForEditingGroup
    javascript_tag <<-EOS
      function validate_edit_project_group_name(form) {
        var res = true;

        var project_group_name = form.project_group_name.value;

        if (project_group_name.length > 30){
          res = false;
          Element.show('project_group_edit_error_max_length');
          Element.hide('project_group_edit_error_no_length');
        }else if (project_group_name.length < 5){
          res = false;
          Element.show('project_group_edit_error_no_length');
          Element.hide('project_group_error_max_length');
        }else{
          Element.hide('project_group_edit_error_max_length');
          Element.hide('project_group_edit_error_no_length');
        }

        return res;
    }

    EOS
  end



  def project_group_fields(f, pg, sub_action='new')
    render "project_groups/fields/#{sub_action}",  :f => f, :project_group => pg
  end

  def options_for_owner_project_group(group_roles)
    group_roles.map {|gr| [ gr.user.login, gr.user_id ]}
  end

  def options_for_change_project_group_owner(project_group_id)

    project_group = ProjectGroup.find(project_group_id)
    user = User.find(project_group.user_id)

    people_list = [user.id]
    options = [[ user.login, user.id ]]



    projects = Project.where(:project_group_id => project_group_id)
    projects.each do |pr|
      pr.people.each do |pe|
        if not people_list.include?(pe.user_id)
          people_list.push(pe.user_id)
          u = User.find(pe.user_id)
          options.push([u.login,u.id])
        end
      end
    end

    options
  end

  # Is it used??
  def delete_project_group_link(project_group)
    link_to '',
    project_group_path(project_group),
    :method => :delete,
    :class => 'big_trash_icon',
    :confirm => t('project_groups.fields.confirm_delete'),
    :title => t('project_groups.fields.forever')
  end

  def role_name_by_number(n)
    if n == 0
      t('project_groups.observer')
    elsif n == 1
      t('project_groups.commenter')
    elsif n == 2
      t('project_groups.participant')
    elsif n == 3
      t('project_groups.admin')
    end
  end

  def jsPreferencesFormValidation
    javascript_tag <<-EOS
      function validate_project_group_edit(form) {
        var project_group_name_field = document.getElementById("project_group_name_edit")
        var res = true;

        if (project_group_name_field.value.length < 1) {
          project_group_name_field.up(0).setAttribute("class", "field_with_errors");
          Element.show('project_group_missing_name_error');
          Element.hide('project_group_error_max_length_edit');
          res = false;
        }else if (project_group_name_field.value.length > 30){
          project_group_name_field.up(0).setAttribute("class", "field_with_errors");
          Element.show('project_group_error_max_length_edit');
          Element.hide('project_group_missing_name_error');
          res = false;
        }else{
          Element.hide('project_group_error_max_length_edit');
          Element.hide('project_group_missing_name_error');
        }
        return res;
      }
    EOS
  end

end
