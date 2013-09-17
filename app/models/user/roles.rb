class User

  def super_admin?
    self.admin
  end

  def observable?(user)
    projects_shared_with(user).any? || user == self
  end
  
  def can_search?
    Colcentric.config.allow_search
  end
  
end