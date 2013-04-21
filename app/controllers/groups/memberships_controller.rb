#
#     group_members GET    /groups/:group_id/members          {:action=>"index"}
#                   DELETE /groups/:group_id/members/:id      {:action=>"destroy"}
#                   POST   /groups/:group_id/members/:id?user_name=x      {:action=>"create"}
#

class Groups::MembershipsController < Groups::BaseController

  guard :index => :may_list_memberships?,
        :destroy => :may_destroy_membership?,
        :create => :may_create_membership?

  #
  # list all the memberships
  #
  def index
    if federation_view?
      @memberships = @group.federatings.paginate(pagination_params)
    else
      @memberships = @group.memberships.paginate(pagination_params)
    end
  end

  #
  # immediately destroy a membership
  #
  def destroy
    @membership.group.remove_user! @membership.user # memberships must be destroyed via group.remove_user!
    render :update do |page|
      page.hide dom_id(@membership)
    end
  end

  #
  # add someone directly to a group
  #
  def create
    if @group && @user
      @group.add_user! @user
      index # load @memberships
      success
      render :update do |page|
        standard_update(page)
        page.replace 'group_membership_list', :partial => 'groups/memberships/list'
      end
    else
      raise_not_found params[:user_name]
    end
  end

  protected

  def fetch_group
    super
    if action?(:destroy)
      if federation_view?
        @membership = @group.federatings.find(params[:id])
      else
        @membership = @group.memberships.find(params[:id])
      end
    elsif action?(:create)
      if params[:user_name]
        @user = User.find_by_login(params[:user_name])
      end
    end
  end

  def federation_view?
    params[:view] == 'groups'
  end
  helper_method :federation_view?

end

