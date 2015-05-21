#
# All the controllers that have sidebar and popup controls inherit from
# this controller.
#
class Pages::SidebarsController < ApplicationController

  before_filter :fetch_page
  before_filter :login_required
  before_filter :authorization_required
  permissions :pages
  guard :may_edit_page?
  layout nil

  helper 'pages/base', 'pages/sidebar'

  def show
    render template: 'pages/sidebar/reset'
  end

  protected

  def close_popup
    render template: 'pages/sidebar/close_popup'
  end

  def refresh_sidebar
   render template: 'pages/sidebar/reset'
  end

  def fetch_page
    @page = Page.find params[:page_id]
    if logged_in?
      # grab the current user's participation from memory
      @upart = @page.participation_for_user(current_user)
    end
  end

end
