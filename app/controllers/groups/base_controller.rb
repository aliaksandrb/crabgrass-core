class Groups::BaseController < ApplicationController

  before_filter :fetch_group
  permissions 'groups'
  helper 'groups/links'

  protected

  def fetch_group
    # group might be preloaded by DispatchController
    @group ||= Group.find_by_name(params[:group_id] || params[:id])
  end

  def setup_context
    if @group and !@group.new_record?
      Context.find(@group)
    end
  end

  ##
  ## PATH ALIASES
  ##
  ## sometimes it is nice to rely on the way rails will guess resource
  ## routes based on the class. so, we alias some of the group routes to be
  ## also supported by networks, councils, and committees.
  ##

  def self.path_alias(path_method)
    path_method = path_method.to_s
    for type in ['network', 'committee', 'council']
      new_method = path_method.sub(/^group/, type)
      alias_method new_method, path_method
      helper_method new_method
    end
  end

  path_alias :group_avatars_path
  path_alias :group_avatar_path

end

