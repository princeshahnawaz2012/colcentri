class Organization
  
  def new_invitation(user, params)
    self.invitations.new(params).tap { |invitation|
      invitation.user = user
    }
  end
  
  def create_invitation(user, params)
    self.invitations.new(params).tap { |invitation|
      invitation.user = user
      invitation.save
    }
  end

end