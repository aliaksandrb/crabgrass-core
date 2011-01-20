#
# These are the before and after filters for Pages::BaseController.
# They live here because there are so many of them.
#

module Pages::BeforeFilters

  protected

  ##
  ## BEFORE FILTERS
  ##

  def default_fetch_data
    if @page.nil? 
      # if page not yet loaded by dispatch controller...
      id = params[:page_id] || params[:id]
      @page = Page.find(id)
    end
    # grab the current user's participation from memory
    @upart = (@page.participation_for_user(current_user) if logged_in?)
    fetch_data
    true
  end
 
  def default_setup_options
    if request.get?
      options.show_posts = action?(:show) || action?(:print)
      options.show_reply = false
      options.title = @page.title
    end
    setup_options
    true
  end

  def choose_layout
    return 'default' if params[:action] == 'create'
    return 'page'
  end

  # don't require a login for public pages
  def login_or_public_page_required
    if action_name == 'show' and @page and @page.public?
      true
    else
      return login_required
    end
  end
  
  def load_posts
    if options.show_posts and request.get? and !@page.nil?
      @discussion ||= (@page.discussion ||= Discussion.new)
      current_page = params[:posts] || @discussion.last_page
      @posts = Post.visible.paginate_by_discussion_id(@discussion.id,
        :order => "created_at ASC", :page => current_page,
        :per_page => current_site.pagination_size, :include => :ratings)
      if options.show_reply
        @post = Post.new
      end
    end
  end

  ##
  ## AFTER FILTERS
  ##

  def update_viewed
    if @upart and @page
      @upart.viewed_at = Time.now
      @upart.notice = nil
      @upart.viewed = true
    end
    true
  end

  def save_if_needed
    @upart.save if @upart and !@upart.new_record? and @upart.changed? and !@upart.readonly?
    @page.save if @page and !@page.new_record? and @page.changed? and !@page.readonly?
    true
  end

  def update_view_count
    return true unless @page and @page.id
    action = case params[:action]
      when 'create' then :edit
      when 'edit' then :edit
      when 'show' then :view
    end
    return true unless action

    group = current_site.tracking? && @group
    group ||= current_site.tracking? && @page.owner.is_a?(Group) && @page.owner
    user  = current_site.tracking? && @page.owner.is_a?(User) && @page.owner
    Tracking.insert_delayed(
      :page => @page, :current_user => current_user, :action => action,
      :group => group, :user => user
    )
    true
  end

end

