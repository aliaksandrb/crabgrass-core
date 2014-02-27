class Groups::DirectoryController < ApplicationController
  skip_before_filter :login_required
  skip_before_filter :authorization_required
  before_filter :set_default_path

  stylesheet 'directory'
  helper 'groups/directory'
  permission_helper 'groups/structures'

  def index
    @groups = groups_to_display.order(:name).paginate(pagination_params)
  end

  protected

  def set_default_path
    if params[:path].empty?
      params[:path] = default_path
    end
  end

  def default_path
    if logged_in? && current_user.groups.any?
      'my'
    else
      'search'
    end
  end

  helper_method :my_groups?

  def my_groups?
    params[:path].try(:include?, 'my')
  end

  def groups_to_display
    if !logged_in?
      Group.with_access(:public => :view).groups_and_networks
    elsif my_groups?
      current_user.primary_groups_and_networks
    else
      Group.with_access(current_user => :view).groups_and_networks
    end
  end
end

