class Pages::PostsController < ApplicationController
  include Common::Tracking::Action

  include_controllers 'common/posts'

  permissions 'pages'
  permissions 'posts'
  helper 'pages/post'

  prepend_before_filter :fetch_data
  before_filter :login_required, except: :show
  before_filter :authorization_required
  guard :may_ALIAS_post?
  guard show: :may_show_page?
  guard index: :may_show_page?

  track_actions :create, :update, :destroy

  # if something goes wrong with create, redirect to the page url.
  rescue_render create: lambda { |controller| redirect_to(page_url(@page)) }

  # do we still want this?...
  # cache_sweeper :social_activities_sweeper, :only => [:create, :save, :twinkle]

  # js action to rerender the posts
  def index
    @posts = @page.posts(pagination_params)
    @post = Post.new
    # maybe? :anchor => @page.discussion.posts.last.dom_id), :paging => params[:paging] || '1')
  end

  def show
    redirect_to page_url(@post.discussion.page) + "#posts-#{@post.id}"
  end

  def create
    if @post = @page.add_post(current_user, post_params)
      redirect_to action: :index
    end
  end

  #
  # I would like this to be in an add-on...
  #
  #  def twinkle
  #    if rating = @post.ratings.find_by_user_id(current_user.id)
  #      rating.update_attribute(:rating, 1)
  #    else
  #      rating = @post.ratings.create(:user_id => current_user.id, :rating => 1)
  #    end

  #    # this should be in an observer, but oddly it doesn't work there.
  #    TwinkledActivity.create!(
  #      :user => @post.user, :twinkler => current_user,
  #      :post => {:id => @post.id, :snippet => @post.body[0..30]}
  #    )
  #  end

  #  def untwinkle
  #    if rating = @post.ratings.find_by_user_id(current_user.id)
  #      rating.destroy
  #    end
  #  end

  protected

  def fetch_data
    @page = Page.find(params[:page_id])
    if params[:id]
      @post = @page.discussion.posts.find(params[:id], include: :discussion)
      raise PermissionDenied.new unless @post
    end
  end

  def post_params
    params.require(:post).permit(:body)
  end

  def track_action
    super item: @post
  end
end

