class GroupCreatedActivity < Activity

  validates_format_of :subject_type, with: /Group/
  validates_presence_of :subject_id

  alias_attr :group, :subject
  alias_attr :user,  :item

  # when build via Activity.track from the controller, the user who created
  # the group will be current_user
  alias_method :current_user=, :user=

  def description(view=nil)
    I18n.t(:activity_group_created,
        user: user_span(:user),
        group_type: group_class(:group),
        group: group_span(:group))
  end

  def icon
    'plus'
  end

end
