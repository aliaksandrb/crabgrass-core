class Me::AvatarsController < Me::BaseController

  include_controllers 'common/avatars'
  include_controllers 'common/always_perform_caching'
  before_filter :setup
  cache_sweeper :user_sweeper

  protected

  def setup
    @entity = current_user
    @success_url = me_settings_url
  end

  def user_avatars_path(user, avatar)
    me_avatar_path(avatar)
  end
  helper_method :user_avatars_path

end

