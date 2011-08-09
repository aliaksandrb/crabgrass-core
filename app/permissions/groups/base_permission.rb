#
# this is shared by all the Groups::XxxController classes
# in addition to their individual permission helpers
#

module Groups::BasePermission

  protected

  ##
  ## BASIC GROUP CRUD
  ##

  def may_show_group?(group = @group)
    current_user.may? :view, group
  end

  def may_people_group?(group=@group)
    may_list_memberships?(group)
  end
  alias_method :may_list_groups_group?, :may_people_group?


  def may_update_group?(group = @group)
    logged_in? and current_user.may?(:admin, group)
  end
  alias_method :may_edit_group?, :may_update_group?

  def may_destroy_group?(group = @group)
    # has a council
    if group.council != group and group.council.users.size == 1
      current_user.may?(:admin, group)
      # disabled until release 0.5.1
      false
    elsif group.council == group
      # no council
      group.users.size == 1 and
        current_user.member_of?(group)
    end
  end

  def may_create_group?(parent = @group)
    logged_in? and (parent.nil? || current_user.may?(:admin, parent))
  end
  alias_method :may_new_group?, :may_create_group?

  def may_create_council?(group = @group)
    Conf.councils and
    group.parent_id.nil? and
    current_user.may?(:admin, group)
  end

  def may_create_network?
    Conf.networks and
    logged_in?
  end

  ##
  ## Group Settings
  ##

  def may_show_groups_settings?(group = @group)
    current_user.may? :admin, group
  end

  def may_update_groups_settings?(group = @group)
    current_user.may? :admin, group
  end


  ##
  ## GROUP FEATURED PAGES
  ##
  def may_edit_featured_pages?(group = @group)
    group and current_user.may?(:admin, group)
  end

  ##
  ## GROUP MENU ITEMS
  ##
  def may_edit_menu?(group = @group)
    group and
    current_user.may?(:admin, group) and
    group == Site.current.network
  end

  ##
  ## ORGANIZATIONAL PERMISSIONS
  ##

  def may_show_subcommittees_of_group?(group = @group)
    return false if !Conf.committees
    return false if group.parent_id
    current_user.may? :see_committees, group
  end

  def may_create_committees?(group = @group)
    return false if !Conf.committees
    current_user.may?(:admin, group) and group.parent_id.nil?
  end

  def may_show_networks_of_group?(group = @group)
    return false if !Conf.networks
    return false if group.parent_id
    current_user.may? :see_networks, group
  end

  def may_show_affiliations?(group = @group)
    may_show_networks_of_group?(group) or
    may_show_subcommittees_of_group?(group) or
    group.real_council
  end

  ##
  ## EXTRA
  ##

  def may_join_chat?(group=@group)
    current_site.chat? and current_user.member_of?(group) and !group.committee?
  end

  def may_create_group_page?(group=@group)
    logged_in? and group and current_user.member_of?(group)
  end

  def may_edit_appearance?(group=@group)
    current_user.may?(:admin,group)
  end

  ##
  ## SEARCHING
  ##

  alias_method :may_search_group?, :may_show_group?
  alias_method :may_archive_group?, :may_show_group?
  alias_method :may_tags_group?, :may_show_group?
  alias_method :may_discussions_group?, :may_show_group?
  alias_method :may_tasks_group?, :may_show_group?
  alias_method :may_trash_group?, :may_create_group_page?

  # no listing of contributions of group members
  def may_contributions_group?(group=@group)
    false
  end

end

