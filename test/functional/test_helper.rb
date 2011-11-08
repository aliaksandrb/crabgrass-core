require File.dirname(__FILE__) + '/../test_helper'

class ActionController::TestCase

  protected

  def run_before_filters(action=nil, params = {})
    @controller.stubs(:action_name).returns(action.to_s) if action
    params.reverse_merge! :action => action,
      :controller => @controller.class.controller_path
    @controller.stubs(:params).returns(params)
    session = ActionController::TestSession.new
    @controller.stubs(:session).returns(session)
    @request.stubs(:session).returns(session)
    chain = @controller.class.filter_chain
    @controller.send :run_before_filters, chain, 0, 0
  end

  # get assigns without going through the whole request
  def assigned(name)
    @controller.instance_variable_get("@#{name}")
  end

  # this should give us access to Flash.now flashes
  def flashed
    @controller.send(:flash)
  end
end
