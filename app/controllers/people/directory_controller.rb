class People::DirectoryController < ApplicationController

# will need permissions, pagination, improved display

  def index
    if friends?
      @users = current_user.friends.paginate(pagination_params)
    elsif peers?
      @users = current_user.peers.paginate(pagination_params)
    else
      @users = User.paginate(pagination_params)
    end
  end
  
  protected

#  VIEW_KEYWORDS = ['friends', 'peers']

  def friends?
    params[:path].try.include? 'friends'
  end

  def peers?
    params[:path].try.include? 'peers'
  end
end

