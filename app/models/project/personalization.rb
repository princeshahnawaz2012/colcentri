class Project
  # DISABLED
  # See models/Project.rb to activate it

  # Also add this on views/projects/fields/_new.haml and _settings.haml
  # .check_box.archived
  # = f.label :personalization, t('projects.fields.personalization_html')
  # = f.select :personalization, options_for_project_personalization()

  # In people/index.haml
  # - @current_project.is_educational? ? role = 1 : role = 2

  # project/initializers.rb
  # default role is commenter for educational projects
  #  params[:role] = Person::ROLES[:commenter] if is_educational?


  PERSONALIZATION = {:none => 0, :educational => 1}

  scope :educational, :conditions => {:personalization => PERSONALIZATION[:educational]}


  def is_educational?
    personalization == PERSONALIZATION[:educational]
  end
  
end