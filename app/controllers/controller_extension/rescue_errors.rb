#
# Handles exceptions for all crabgrass controllers.
#
# This is an easy way to report an error in crabgrass:
#
#   raise ErrorMessage.new("i am sorry dave, i can't do that right now")
#
# Or, you can use the helper:
#
#   raise_error("i am sorry dave, i can't do that right now")
#
# For not found, use:
#
#   raise_not_found(I18n.t(:invite))
#
# Some people might consider this bad programming style, since it uses exceptions
# for error messages and they consider exceptions to be only for the unexpected.
#
# However, raise_error is pretty explicit, and is just an easy way to bail out
# of the current controller and report the error. The problem is, there is a lot
# of common logic to error reporting, and it seems a shame to repeat this everywhere
# you want to display a simple error message.
#
# The use of 'raise ErrorMessage.new' is more like a goto, and could lead to problems.
# In some cases, however, it is nice to put sanity checking deep in the models where
# it would be impractical to expose an api for testing the validity of every oject.
#

module ControllerExtension::RescueErrors

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      # order of precedence is bottom to top.
      rescue_from ActiveRecord::RecordInvalid, :with => :render_error
      rescue_from CrabgrassException, :with => :render_error
      rescue_from ErrorNotFound,    :with => :render_not_found
      rescue_from PermissionDenied, :with => :render_permission_denied
      #rescue_from ActionController::InvalidAuthenticityToken, :with => :render_csrf_error
      #helper_method :rescues_path
      #alias_method_chain :rescue_action_locally, :js
    end
  end

  module ClassMethods
    #
    # for automatic rendering of errors, this helps us figure out what
    # action we should render, if it is non-standard.
    #
    # example:
    #
    #   class RobotController < ApplicationController
    #     rescue_render :update => :show
    #   end
    #
    #   this will render action :show when there is a caught error exception for :update
    #
    # standard default is:
    #   update -> edit
    #   create -> new
    #   otherwise, render current action
    #
    def rescue_render(hsh=nil)
      if hsh
        write_inheritable_attribute "rescue_render", HashWithIndifferentAccess.new(hsh)
      else
        read_inheritable_attribute "rescue_render"
      end
    end
  end

  protected

#  # allows us to set a new path for the rescue templates
#  def rescues_path(template_name)
#    file = "#{RAILS_ROOT}/app/views/rescues/#{template_name}.erb"
#    if File.exists?(file)
#      return file
#    else
#      return super(template_name)
#    end
#  end

#  # handles suspected "cross-site request forgery" errors
#  def render_csrf_error(exception=nil)
#    render :template => 'account/csrf_error', :layout => 'default'
#  end

  # shows a generic not found page or error message, customized
  # by any message in the exception.
  def render_not_found(exception=nil)
    respond_to do |format|
      format.html do
        render_not_found_html(exception)
      end
      format.js do
        render_error_js(exception)
      end
    end
  end

  # show a permission denied page, or prompt for login

  def render_permission_denied(exception)
    if !logged_in?
      exception = AuthenticationRequired.new(exception.to_s)
    end
    respond_to do |format|
      format.html do
        render_auth_error_html(exception)
      end
      format.js do
        render_error_js(exception)
      end
      format.xml do
        headers["Status"]           = "Unauthorized"
        headers["WWW-Authenticate"] = %(Basic realm="Web Password")
        render :text => "Could not authenticate you", :status => '401 Unauthorized'
      end
    end
  end

  # renders an error message or messages
  def render_error(exception=nil, options={})
    #if exception
    #  options[:template] ||= exception.template
    #  options[:redirect] ||= exception.redirect
    #  options[:record] ||= exception.record
    #  options[:status] ||= exception.status
    #end
    respond_to do |format|
      format.html do
        render_error_html(exception, options)
      end
      format.js do
        render_error_js(exception, options)
      end
    end
  end

  #
  # override the default 'rescue_action_locally' so that we can print an error
  # message when the request is an ajax one.
  #
  # How is this different than 'render_error' with format.js?
  #
#  def rescue_action_locally_with_js(exception)
#    respond_to do |format|
#      format.html do
#        if RAILS_ENV == "production" or RAILS_ENV == "development"
#          rescue_action_locally_without_js(exception)
#        else
#          render :text => exception
#         end
#      end
#      format.js do
#        add_variables_to_assigns
#        @template.instance_variable_set("@exception", exception)
#        @template.instance_variable_set("@rescues_path", File.dirname(rescues_path("stub")))
#        @template.send!(:assign_variables_from_controller)
#        render :template => 'rescues/diagnostics.rjs', :layout => false
#      end
#    end
#  end

  private

  def render_error_html(exception=nil, options={})
    if options[:redirect]
      redirect_to options[:redirect]
    end
    if exception
      alert_message :error, exception
    end
    if !performed? and !@performed_render
      if options[:template]
        render :template => options[:template], :status => options[:status]
      elsif options[:action]
        render :action => options[:action], :status => options[:status]
      elsif self.class.rescue_render && self.class.rescue_render[params[:action]]
        render :action => self.class.rescue_render[params[:action]]
      elsif params[:action] == 'update'
        render :action => 'edit'
      elsif params[:action] == 'create'
        render :action => 'new'
      end
    end
  end

  def render_auth_error_html(exception)
    alert_message exception, :later
    if logged_in?
      # fyi, this template will eat the alert_message
      render :template => 'error/permission_denied', :layout => 'notice'
    else
      redirect_to login_path, :redirect => request.request_uri
    end
  end

  def render_not_found_html(exception)
    render :template => 'error/not_found', :status => :not_found, :layout => 'notice', :locals => {:exception => exception}
  end

  def render_error_js(exception=nil, options={})
    if exception
      alert_message :error, exception
    end
    render :update do |page|
      hide_spinners(page)
      update_alert_messages(page)
    end
  end

  #def flash_auth_error(mode)
  #  if mode == :now
  #    flsh = flash.now
  #  else
  #    flsh = flash
  #  end
  #
  #  if logged_in?
  #    add_flash_message(flsh, :title => I18n.t(:alert_permission_denied), :error => I18n.t(:permission_denied_description))
  #  else
  #    add_flash_message(flsh, :title => I18n.t(:login_required), :type => 'info', :text => I18n.t(:login_required_description))
  #  end
  #end

end

