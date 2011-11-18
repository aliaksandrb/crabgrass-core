#
# methods and helpers for context and navigation that should
# be available in all controllers.
#

module Common::Application::ContextNavigation

  def self.included(base)
    base.class_eval do
      helper_method :current_context
      helper_method :current_navigation
    end
  end

  protected

  ##
  ## HELPERS
  ##
  ## These are called by the layout if they want navigation or context.
  ## Controllers can override context() to define their own.
  ##

  #
  # get access to the current context.
  #
  def current_context
    @context ||= begin
      context = setup_context() # should be defined by the current controller.

      # Typically, the correct @user or @group should be loaded in
      # by the dispatcher. However, there might arise cases where the
      # url does not actually contain the correct entity for the
      # current context. In these cases, we ensure @group or @user is
      # set, as appropriate.

      if context
        if @user.nil? and context.is_a?(Context::User)
          @user = context.entity
        elsif @group.nil? and context.is_a?(Context::Group)
          @group = context.entity
        end
      end
      context
    end
  end

  #
  # sets up the navigation variables from the current theme.
  #
  # The 'active' blocks of the navigation definition are evaluated in this
  # method, so any variables needed by those blocks must be set up before this
  # is called.
  #
  # I don't see any reason why a controller would want to override this, but they
  # could if they really wanted to.
  #
  def current_navigation
    @navigation ||= begin
      navigation = {}
      navigation[:global] = current_theme.navigation.root
      if navigation[:global]
        navigation[:context] = navigation[:global].currently_active_item
        if navigation[:context]
          navigation[:local] = navigation[:context].currently_active_item
        end
      end
      navigation = setup_navigation(navigation) # allow controller change to modify @navigation
      navigation
    end
  end

  ##
  ## OVERRIDE
  ##

  def setup_context
    # this can be implemented by controller subclasses
  end

  def setup_navigation(nav)
    return nav
    # this can be implemented by controller subclasses
  end

  ##
  ## DETECTION
  ##

  #
  # returns true if the current display context matches the symbol.
  # options are :none, :me, :group, or :user
  #
  def context?(symbol)
    case symbol
      when :none  then @context.nil?
      when :me    then @context.is_a?(Context::Me)
      when :group then @context.is_a?(Context::Group)
      when :user  then @context.is_a?(Context::User)
    end
  end

  #
  # returns the group and the page for a particular context path
  # eg.
  #   entity, page = resolve_context('riseup', 'minutes')
  #
  # This would correspond to: https://we.riseup.net/riseup/minutes
  #
  # currently, i think this is only used by the wiki renderer
  #
  def resolve_context(context_name, page_name, allow_multiple_results=false)

    #
    # Context
    #

    if context_name =~ /\ /
      # we are dealing with a committee!
      context_name.sub!(' ','+')
    end

    group = Group.find_by_name(context_name)
    user  = User.find_by_login(context_name) unless group

    #
    # Page
    #

    if page_name.nil?
      unless group || user
        raise ActiveRecord::RecordNotFound.new
      end
    elsif page_name =~ /[ +](\d+)$/ || page_name =~ /^(\d+)$/
      # if page handle ends with [:space:][:number:] or entirely just numbers
      # then find by page id. (the url actually looks like "my-page+52", but
      # pluses are interpreted as spaces). find by id will always return a
      #  globally unique page so we can ignore context
      page = find_page_by_id( $~[1] )
    elsif group
      # find just pages with the name that are owned by the group
      # no group should have multiple pages with the same name
      page = find_page_by_group_and_name(group, page_name)
    elsif user and !allow_multiple_results
      page = find_page_by_user_and_name(user, page_name)
    elsif user and allow_multiple_results
      page = find_pages_by_user_and_name(user, page_name)
    end

    raise ActiveRecord::RecordNotFound.new unless page

    return [(group||user), page]
  end

  private

  def find_page_by_id(id)
    Page.find_by_id(id.to_i, :include => nil)
  end

  # almost every page is fetched using this function.
  # Page names should be unique across all the groups in the namespace.
  def find_page_by_group_and_name(group, name)
    ids = Group.namespace_ids(group.id)
    Page.find(:first, :conditions => ['pages.name = ? AND group_participations.group_id IN (?)', name, ids], :joins => :group_participations)
  end

  def find_page_by_user_and_name(user, name)
    user.pages.find(:first, :conditions => ['pages.name = ?',name])
  end

  def find_pages_by_user_and_name(user, name)
    user.pages.find(:all, :conditions => ['pages.name = ?',name])
  end

end

