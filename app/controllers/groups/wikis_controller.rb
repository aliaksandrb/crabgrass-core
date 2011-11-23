class Groups::WikisController < Groups::BaseController

  include_controllers 'common/wiki'

  # show might be allowed when not logged in
  before_filter :login_required, :except => :show
  before_filter :authorized?, :only => :show

  layout proc{ |c| c.request.xhr? ? false : 'sidecolumn' }

  def new
    if @wiki = @profile.wiki
      # the wiki has been created by another user since the link to
      # new was displayed - so we just display it.
      render :template => '/common/wiki/show'
    else
      @wiki = Wiki.new
      render :template => '/common/wiki/edit'
    end
  end

  def create
    if !params[:cancel]
      if @wiki = @profile.wiki
        # another user has created this group wiki
        # we will save this one as a newer version
        @wiki.update_document!(current_user, nil, params[:wiki][:body])
        notice :wiki_existed_new_version_created.t
      else
        @wiki = @profile.create_wiki :version => 0,
          :body => params[:wiki][:body],
          :user => current_user
        success
      end
    end
    redirect_to entity_path(@group || @page)
  end


  protected

  # @group is fetched in Groups::BaseController
  def fetch_context
    @profile = fetch_private? ?
      @group.profiles.private :
      @group.profiles.public
  end

  def fetch_private?
    params[:wiki] && params[:wiki][:private] or
    params[:private]
  end

  def fetch_wiki
    @wiki = @group.wikis.find(params[:id]) # this could be nil
  end

end
