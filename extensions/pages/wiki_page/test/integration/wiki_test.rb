require 'javascript_integration_test'

class WikiTest < JavascriptIntegrationTest
  include Integration::Wiki
  include Integration::Navigation

  def setup
    super
    own_page :wiki_page
    login
    click_on own_page.title
  end

  def test_writing_initial_version
    assert_page_tab "Edit"
    content = update_wiki
    assert_content content
    assert_page_tab "Show"
    assert_success "Changes saved"
  end

  def test_cancel_edit
    assert_page_tab "Edit"
    click_button 'Cancel'
    assert_page_tab "Show"
  end

  def test_format_help
    find('.edit_wiki').click_on 'Editing Help'
    help = windows.last
    within_window help do
      assert_content 'GreenCloth'
    end
  end

  def test_versioning_with_diff
    versions = []
    3.times do
      versions << update_wiki
      assert_content versions.last
    end
    click_page_tab "Versions"
    assert_wiki_unlocked
    assert_no_content "Version 4"
    find("span.b", text: "3", exact: false).click
    clicking "previous" do
      assert_selector 'ins', text: versions.pop
      assert_selector 'del', text: versions.last if versions.last.present?
    end
  end

  def test_wiki_toc
    content = update_wiki <<-EOWIKI
[[toc]]

h1. test table of content

h2. with nested section

and some content
    EOWIKI
    assert_content 'table of content'
    assert_selector 'li.toc1'
  end

  def assert_wiki_unlocked
    request_urls = page.driver.network_traffic.map(&:url)
    assert request_urls.detect{|u| u.end_with? '/lock'}.present?
    # the unlock request is triggered from onbeforeunload.
    # So the response will never be registered by the page.
    # In order to prevent the check for pending ajax from failing...
    page.driver.clear_network_traffic
  end

end
