#
# Controllers that include this must define:
#
# request_path(*args) -- returns a path for the args. First arg is a request object.
#
# requests_path(*args) -- used for request index.
#
module Common::Requests

  def self.included(base)
    base.class_eval do
      helper_method :current_state
      helper_method :request_path
      helper_method :requests_path
      before_filter :fetch_request, only: [:update, :destroy, :show]
      after_filter :track_activity, if: :approved?
    end
  end

  #
  # show the details of a request
  #
  # this is needed for the case when a user visits a person or group profile
  # and sees that a request is pending and wants to click on a link for more information.
  #
  def show
    render template: 'common/requests/show'
  end

  #
  # update action changes the state of the request
  #
  def update
    if mark
      @request.mark!(mark, current_user)
      success I18n.t(@request.name), success_message
    end
    render template: 'common/requests/update'
  end

  #
  # destroy a request.
  # uses model permissions.
  #
  def destroy
    @request.destroy_by!(current_user)
    notice request_destroyed_message, :later
    render(:update) {|page| page.redirect_to requests_path}
  end

  protected

  def current_state
    case params[:state]
      when 'approved' then :approved;
      when 'rejected' then :rejected;
      else :pending;
    end
  end

  def request_destroyed_message
    :thing_destroyed.tcap thing: I18n.t(@request.name, count: 1)
  end

  #def left_id(request)
  #  dom_id(request, :panel_left)
  #end

  #def right_id(request)
  #  dom_id(request, :panel_right)
  #end

  def request_path(*args)
    raise 'you forgot to override this method'
  end

  def requests_path(*args)
    raise 'you forgot to override this method'
  end

  def fetch_request
    @request = request_context.find(params[:id])
    if params[:code] && @request.recipient != current_user
      @request.try.redeem_code!(current_user)
    end
  end

  def request_context
    if params[:code]
      Request.where(code: params[:code])
    else
      Request.visible_to(current_user)
    end
  end

  def mark
    case params[:mark]
      when 'reject' then :reject;
      when 'approve' then :approve;
    end
  end

  def success_message
    if approved?
      msg = :approved_by_entity.t(entity: current_user.name)
    elsif mark == :reject
      msg = :rejected_by_entity.t(entity: current_user.name)
    end
  end

  def track_activity
    super request.event, request: @request, approved_by: current_user
  end

  def approved?
    mark == :approve
  end
end

