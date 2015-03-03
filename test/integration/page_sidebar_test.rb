# encoding: utf-8

require 'javascript_integration_test'

class PageSidebarTest < JavascriptIntegrationTest
  include GroupRecords

  def setup
    super
    @user = users(:blue)
    own_page
    login
    click_on own_page.title
  end

  def test_watch
    watch_page
    assert_page_watched
    unwatch_page
    assert_page_not_watched
  end

  def test_stars
    star_page
    assert_page_starred
    remove_star_from_page
    assert_page_not_starred
  end

  def test_share_with_user
    share_page_with users(:red)
    assert_page_users user, users(:red)
  end

  def test_share_with_group
    share_page_with groups(:animals)
    assert_page_groups groups(:animals)
  end

  # regression test for #7834
  def test_sharing_preserves_stars
    star_page
    assert_page_starred
    share_page_with users(:red)
    assert_page_starred
  end
  
  def test_trash
    path = current_path
    delete_page
    assert_content 'Notices'
    assert_no_content own_page.title
    assert_equal '/me', current_path
    visit path
    undelete_page
    assert_content 'Delete Page'
    click_on 'Dashboard'
    assert_content own_page.title
  end

  def test_destroy
    click_on 'Delete Page'
    choose 'Destroy Immediately'
    click_button 'Delete'
    # finish deleting...
    assert_content 'Notices'
    assert_no_content own_page.title
    assert_nil Page.where(id: own_page.id).first
  end

  def test_tag
    tags = %w/some tags for this páge/
    tag_page tags
    assert_page_tags tags
  end

  def test_attach_file
    attach_file_to_page
    assert_selector '#attachments a.thumbnail'
  end
end
