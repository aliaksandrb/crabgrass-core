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

  def test_sharing_with_user
    share_page_with users(:red)
    assert_page_users user, users(:red)
  end

  def test_sharing_with_group
    share_page_with groups(:animals)
    assert_page_groups groups(:animals)
  end

  def test_tagging
    tags = %w/some tags for this páge/
    tag_page tags
    assert_page_tags tags
  end

  def test_trash
    path = current_path
    delete_page
    assert_no_content own_page.title
    assert_equal '/me', current_path
    visit path
    undelete_page
    assert_content 'Delete Page'
    click_on 'Dashboard'
    assert_content own_page.title
  end

  def test_stars
    star_page
    assert_page_starred
    remove_star_from_page
    assert_page_not_starred
  end

  # regression test for #7834
  def test_sharing_preserves_stars
    star_page
    assert_page_starred
    share_page_with users(:red)
    assert_page_starred
  end

  def star_page
    click_on 'Add Star (0)'
  end

  def assert_page_starred
    assert_selector '#star_li.star_16'
  end

  def remove_star_from_page
    click_on 'Remove Star (1)'
  end

  def assert_page_not_starred
    assert_selector '#star_li.star_empty_dark_16'
  end
end
