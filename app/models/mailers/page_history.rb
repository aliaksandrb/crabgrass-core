# TODO: We currently use Site.default to originate from.
# Based on real live site scenarios we might want to make
# this the site where the user actually watched the page
# or the user last visited or the notification was send from.


module Mailers::PageHistory
  def self.included(base)
    base.instance_eval do
      # TODO: figure out which helpers are really needed.
      add_template_helper(Pages::HistoryHelper)
      #add_template_helper(PageHelper)
      #add_template_helper(Page::UrlHelper)
      add_template_helper(Common::Utility::TimeHelper)
    end
  end

  def page_history_single_notification(user, page_history)
    @page_history         = page_history
    @user                 = user
    @site                 = Site.default
    @subject              = "#{@site.title} : #{@page_history.page.title}"
    @body[:page_history]  = @page_history
    setup_watched_notification_email
  end

  def page_history_single_notification_paranoid(user, page_history)
    @page_history         = page_history
    @user                 = user
    @site                 = Site.default
    @subject              = I18n.t(:page_history_mailer_a_page_has_been_modified, :site_title => @site.title)
    @body[:page_history]  = @page_history

    @body[:code] = Code.create!(:user => user, :page => page_history.page)

    setup_watched_notification_email
  end

  def page_history_digest_notification(user, page, page_histories)
    @site                 = Site.default
    @user                   = user
    @subject                = "#{@site.title} : #{page.title}"
    @body[:page]            = page
    @body[:page_histories]  = page_histories
    setup_watched_notification_email
  end

  def page_history_digest_notification_paranoid(user, page, page_histories)
    @site                 = Site.default
    @user                   = user
    @subject                = I18n.t(:page_history_mailer_a_page_has_been_modified, :site_title => @site.title)
    @body[:page]            = page
    @body[:page_histories]  = page_histories

    @body[:code] = Code.create!(:user => user, :page => page)

    setup_watched_notification_email
  end

  protected

  def from_address
    @site.email_sender.gsub('$current_host', @site.domain)
  end

  def setup_watched_notification_email
    @from                 = "#{from_address}"
    @recipients           = "#{@user.email}"
    @body[:site]          = @site
    @body[:user]          = @user
  end
end
