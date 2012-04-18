#
# This controller deals with membership requests. 
#
# e.g. invite, expell, join.
#
# For other types of requests, see Groups::RequestsController.
#

class Groups::MembershipRequestsController < Groups::BaseController

  include_controllers 'common/requests'
  before_filter :login_required

  guard :index => :may_list_membership_requests?,
        :show => :may_list_membership_requests?,
        # permissions handled by model:
        :create => :allow, :update => :allow, :destroy => :allow
  
  def index
    @requests = Request.
      membership_related.
      having_state(current_state).
      send(current_view, @group).
      by_updated_at.
      paginate(pagination_params)
    render :template => 'common/requests/index'
  end

  #
  # RequestToRemoveUser
  # RequestToJoinYou
  # RequestToJoinYourNetwork
  #
  def create
    if type == :join
      create_join_request
    elsif type == :destroy
      create_destroy_request
    end
  end

  protected

  def type
    case params[:type]
      when 'destroy' then :destroy
      when 'join' then :join
    end
  end

  def current_view
    case params[:view]
      when "incoming" then :to_group
      when "outgoing" then :from_group
      else :regarding_group;
    end
  end

  def request_path(*args)
    group_membership_request_path(@group, *args)
  end

  def requests_path(*args)
    group_membership_requests_path(@group, *args)
  end

  def create_join_request
    if !params[:cancel]
      req = RequestToJoinYou.create :recipient => @group, :created_by => current_user
      if req.valid?
        success(:join_request_sent.t(:recipient => req.recipient.display_name))
      else
        error("Invalid request for "+req.recipient.display_name)
      end
    end
    redirect_to entity_url(@group)
  end

  def create_destroy_request
    @entity = Entity.find_by_name!(params[:entity])
    if @entity.is_a? User
      req = RequestToRemoveUser.create! :user => @entity, :group => @group, :created_by => current_user
      membership = @group.memberships.find_by_user_id(@entity.id)
    elsif @entity.is_a? Group
      req = RequestToRemoveGroup.create! :group => @entity, :network => @group, :created_by => current_user
      membership = @group.federatings.find_by_group_id(@entity.id)
    else
      raise_error
    end
    success
    render :update do |page|
      standard_update(page)
      page.replace(dom_id(membership), :partial => "groups/memberships/membership", :locals => {:membership => membership})
    end
  end

end
