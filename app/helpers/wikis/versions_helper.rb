module Wikis::VersionsHelper

  def previous_version_link
    return unless target = @version.previous
    link_to_remote LARROW + :pagination_previous.t,
      :url => wiki_version_path(@wiki, target),
      :update => dom_id(@wiki),
      :method => :get
  end

  def next_version_link
    return unless target = @version.next
    link_to_remote :pagination_next.t + RARROW,
      :url => wiki_version_path(@wiki, target),
      :update => dom_id(@wiki),
      :method => :get
  end

  def classes_for_versions_list(version)
    version == @version ?
      cycle('odd', 'even') + ' active' :
      cycle('odd', 'even')
  end

  def version_number_link(version)
    label = I18n.t :version_number, :version => version.version
    link_to_remote version.version, :url => wiki_version_path(@wiki, version),
      :update => dom_id(@wiki),
      :method => :get
  end

  def version_time_link(version)
    link_to_remote friendly_date(version.updated_at),
      :url => wiki_version_path(@wiki, version),
      :update => dom_id(@wiki),
      :method => :get
  end

  def version_user_link(version)
    link_to_user(version.user, :avatar => :xsmall) if version.user
  end

 def version_user_link_small(version)
   link_to avatar_for(version.user, :xsmall, {:title => version.user.name}), entity_path(version.user) if version.user
 end

  def version_action_links(version)
    link_line version_diff_link(version),
      version_revert_link(version),
      version_delete_link(version)
  end

  def version_diff_link(version)
    return unless version.previous
    link_to :diff_link.t,
      wiki_diff_path(@wiki, version.diff_id)
  end

  def version_revert_link(version)
    return unless may_revert_wiki_version?(version)
    link_to :wiki_version_revert_link.t,
      revert_wiki_version_path(@wiki, version)
  end

  def version_delete_link(version)
    return unless may_destroy_wiki_version?
    link_to :wiki_version_destroy_link.t,
      wiki_version_path(@wiki, version), :method => :delete
  end
end
