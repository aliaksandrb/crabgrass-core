module Me::NoticesHelper
  def dismiss_all_notices_button
    link_to_remote_with_confirm(:dismiss_all_notices.t,
      { confirm: "#{:dismiss_all_notices_confirmation.t}<br>#{:action_cannot_be_undone.t}",
        url: me_notices_destroy_all_path,
        method: :delete,
      }, class: 'btn btn-sm btn-default')
  end
end
