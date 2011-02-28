class Groups::BaseController < ApplicationController

  before_filter :fetch_group
  permissions 'groups/base', 'groups/memberships', 'groups/requests'
  helper 'groups/links'

  protected

  def fetch_group
    # group might be preloaded by DispatchController
    @group ||= Group.find_by_name(params[:group_id] || params[:id])    
  end

  def context
    @context = Context.find(@group)
  end

  # temporarily until permissions are fixed.
  #def authorized?
  #  true
  #end

end

