class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.persisted?
      can :read, Post
      can :manage, Post, :user_id => user.id
    else
      # Guest user are not allowed
    end
  end
end
