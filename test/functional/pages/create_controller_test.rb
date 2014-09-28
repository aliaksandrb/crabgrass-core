require_relative '../../test_helper'

class Pages::CreateControllerTest < ActionController::TestCase

  def setup
    @user  = FactoryGirl.create(:user)
  end

  def test_new_page_view
    login_as @user
    get :new, owner: 'me', type: "wiki"
    assert_equal assigns(:owner), @user
  end


  def test_create_page_for_myself
    login_as @user
    assert_difference "WikiPage.count" do
      post :create,
        owner: 'me',
        page: {title: 'title'},
        type: "wiki",
        page_type: "WikiPage"
    end
    assert_equal @user, Page.last.owner
    assert Page.last.users.include? @user
  end

  def test_create_page_for_group
    @group  = FactoryGirl.create(:group)
    login_as @user
    assert_difference "WikiPage.count" do
      post :create,
        owner: @group.name,
        page: {title: 'title'},
        type: "wiki",
        page_type: "WikiPage"
    end
    assert_equal @group, Page.last.owner
    assert Page.last.users.include? @user
  end

  def test_create_same_name
    login_as @user

    data_ids, page_ids, page_urls = [],[],[]
    3.times do
      post 'create',
        owner: @user,
        page: {title: "dupe"},
        type: "ranked-vote",
        page_type: "RankedVotePage"
      page = assigns(:page)

      assert_equal "dupe", page.title
      assert_not_nil page.id

      # check that we have:
      # a new ranked vote
      assert !data_ids.include?(page.data.id)
      # a new page
      assert !page_ids.include?(page.id)
      # a new url
      assert !page_urls.include?(page.name_url)

      # remember the values we saw
      data_ids << page.data.id
      page_ids << page.id
      page_urls << page.name_url
    end
  end

end

