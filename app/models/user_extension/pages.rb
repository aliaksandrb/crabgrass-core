# -*- coding: utf-8 -*-
#
# A user's relationship to pages
#
# "user_participations" is the join table:
#   user has many pages through user_participations
#   page has many users through user_participations
#
module UserExtension::Pages

  ##
  ## ASSOCIATIONS
  ##

  def self.included(base)
    base.instance_eval do
      has_many :participations,
        class_name: 'UserParticipation',
        dependent: :destroy,
        inverse_of: :user

      has_many :pages, through: :participations do
        def recent_pages
          order('user_participations.changed_at DESC').limit(15)
        end
      end

      has_many :pages_owned, class_name: 'Page', as: :owner, dependent: :nullify
      has_many :pages_created, class_name: 'Page', foreign_key: :created_by_id, dependent: :nullify
      has_many :pages_updated, class_name: 'Page', foreign_key: :updated_by_id, dependent: :nullify

      def self.most_active_on(site, time)
        condition = time && ["user_participations.changed_at >= ?", time]
        joins(user_participations: :pages).
          where(condition).
          where(pages => {site_id: site}).
          where("pages.type != 'AssetPage'").
          group('users.id').
          order('count(user_participations.id) DESC').
          select('users.*, user_participations.changed_at')
      end

      def self.most_active_since(time)
        joins(:user_participations).
          group('users.id').
          order('count(user_participations.id) DESC').
          where("user_participations.changed_at >= ?", time).
          select("users.*")
      end

      def self.not_inactive
        if self.respond_to? :inactive_user_ids
          where("users.id NOT IN (?)", inactive_user_ids)
        end
      end

      # some page data objects belong to users.
      # These need has many relationships so they get cleaned up if a user
      # is destroyed.
      has_many :votes, dependent: :destroy

    end
  end

  # this is used to retrieve pages when vising
  #   /login/page_name
  # for now we only display pages the user actually owns.
  def find_page(name)
    pages_owned.where(name: name).first
  end

  ##
  ## USER PARTICIPATIONS
  ##

  #
  # makes or updates a user_participation object for a page.
  #
  # returns the user_participation, which must be saved for changed
  # to take effect.
  #
  # this method is not called directly. instead, page.add(user)
  # should be used.
  #
  # TODO: delete the user_participation row if it is not really needed
  # anymore (ie, the user won't lose access by deleted it, and inbox,
  # watch, star are all false, and the user has not contributed.)
  #
  def add_page(page, part_attrs)
    clear_access_cache
    part_attrs = part_attrs.dup
    participation = page.participation_for_user(self)
    if participation
      participation.attributes = part_attrs
    else
      # user_participations.build doesn't update the pages.users
      # until it is saved. If you need an updated users list, then
      # use user_participations directly.
      participation = page.user_participations.build(
        part_attrs.merge(
          page_id: page.id, user_id: id,
          resolved: page.resolved?
        )
      )
      participation.page = page
    end
    unless participation.changed_at or page.created_by != self
      participation.changed_at = Time.now
    end
    page.association_will_change(:users)
    participation
  end

  public

  # remove self from the page.
  # only call by page.remove(user)
  def remove_page(page)
    clear_access_cache
    page.users.delete(self)
    page.updated_by_id_will_change!
    page.association_will_change(:users)
    page.user_participations.reset
  end

  # set resolved status vis-à-vis self.
  def resolved(page, resolved_flag)
    find_or_build_participation(page).update_attributes resolved: resolved_flag
  end

  def find_or_build_participation(page)
    page.participation_for_user(self) || page.user_participations.build(user_id: self.id)
  end

  # This should be called when a user modifies a page and that modification
  # should trigger a notification to page watchers. Also, if a page state changes
  # from pending to resolved, we also update everyone's user participation.
  # The page is not saved here, because it might still get more changes.
  # An after_filter should finally save the page if it has not already been saved.
  #
  # options:
  #  :resolved -- user's participation is resolved with this page
  #  :all_resolved -- everyone's participation is resolved.
  #
  def updated(page, options={})
    return if page.blank?
    now = Time.now

    unless page.contributor?(self)
      page.contributors_count += 1
    end

    # update everyone's participation
    if options[:all_resolved]
      page.user_participations.update_all('viewed = 0, resolved = 1')
    else
      page.user_participations.update_all('viewed = 0')
    end

    # create self's participation if it does not exist
    my_part = find_or_build_participation(page)
    my_part.update_attributes(
      changed_at: now, viewed_at: now, viewed: true,
      resolved: (options[:resolved] || options[:all_resolved] || my_part.resolved?)
    )

    # this is unfortunate, because perhaps we have already just modified the page?
    page.resolved = options[:all_resolved] || page.resolved?
    page.updated_at = now
    page.updated_by = self
    page.user_participations.where(watch: true).each do |part|
      PageUpdateNotice.create!(user_id: part.user_id, page: page, from: self)
    end
  end

  ##
  ## PAGE SHARING
  ##

  # Check that +self+ may pester user and has admin access if sharing requires
  # granting new access.
  #
  def may_share!(page,entity,options)
    user  = entity if entity.is_a? User
    group = entity if entity.is_a? Group
    access = options[:access] || options[:grant_access] || :view
    if user
      if page.public? and !self.may?(:pester, user)
        raise PermissionDenied.new(I18n.t(:share_pester_error, name: user.login))
      elsif access.nil?
        if !user.may?(:view,page)
          raise PermissionDenied.new(I18n.t(:share_grant_required_error, name: user.login))
        end
      elsif !user.may?(access, page)
        if !self.may?(:admin,page)
          raise PermissionDenied.new(I18n.t(:share_permission_denied_error))
        elsif !self.may?(:pester, user)
          raise PermissionDenied.new(I18n.t(:share_pester_error, name: user.login))
        end
      end
    elsif group
      unless group.may?(access,page)
        unless self.may?(:admin,page) and self.may?(:pester, group)
          raise PermissionDenied.new(I18n.t(:share_pester_error, name: group.name))
        end
      end
    end
  end

  public



  #
  # From controllers please use PageShare#with. This will also send emais
  # if needed.
  # This method is used in tests though to setup shares.
  #
  def share_page_with_user!(page, user, options={})
    may_share!(page,user,options)
    attrs = {}
    if options[:send_notice]
      attrs[:viewed] = false
      PageNotice.create!(user: user, page: page, from: self, message: options[:send_message])
    end

    default_access_level = :none
    if options.key?(:access) # might be nil
      attrs[:access] = options[:access]
    else
      options[:grant_access] ||= default_access_level
      unless user.may?(options[:grant_access], page)
        attrs[:grant_access] = options[:grant_access] || default_access_level
      end
    end
    upart = page.add(user, attrs)
    upart.save! unless page.changed?
  end

  def share_page_with_group!(page, group, options={})
    may_share!(page,group,options)
    if options.key?(:access) # might be nil
      gpart = page.add(group, access: options[:access])
    else
      options[:grant_access] ||= :view
      gpart = page.add(group, grant_access: options[:grant_access])
    end
    gpart.save! unless page.changed?

    # when we get here, the group should be able to view the page.

    attrs = {}
    users_to_pester = []
    if options[:send_notice]
      attrs[:viewed] = false
      users_to_pester = group.users.with_access(self => :pester)
      users_to_pester.each do |user|
        upart = page.add(user, attrs)
        upart.save! unless page.changed?
      end
      PageNotice.create!(recipients: users_to_pester, page: page, from: self, message: options[:send_message])
    end

    users_to_pester # returns users to pester so they can get an email, maybe.
  end

  # return true if the user may still admin a page even if we
  # destroy the particular participation object
  #
  # this method is VERY expensive to call, and should only be called with caution.
  def may_admin_page_without?(page, participation)
    method = participation.class.name.underscore.pluralize # user_participations or group_participations
    # work with a new, untained page object
    # no changes to it should be saved!
    page = Page.find(page.id)
    page.send(method).delete_if {|part| part.id == participation.id}
    begin
      result = page.has_access!(:admin, self)
    rescue PermissionDenied
      result = false
    end
    result
  end

end
