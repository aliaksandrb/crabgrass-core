class Wikis::BaseController < ApplicationController

  # required to show the banner if wiki is owned by a group.
  permissions 'groups/members', 'groups/base'

  before_filter :fetch_wiki
  before_filter :fetch_context

  helper 'wikis/base'

  VERSIONS_PER_PAGE = 10 # pagination for versions and diffs

  protected
  def fetch_wiki
    @wiki = Wiki.find(params[:wiki_id] || params[:id])
  end

  def fetch_context
    @page = @wiki.page
    @group = @wiki.context if @wiki.context.is_a?(Group)
    @user = @wiki.context if @wiki.context.is_a?(User)
    @context = Context.find(@wiki.context) if @wiki.context
  end

end
