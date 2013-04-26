require_relative '../test_helper'

class Me::PagesControllerTest < ActionController::TestCase
  fixtures :users, :pages

  def test_list_pages
    login_as users(:blue)
    get :index
    assert_response :success
  end

  def test_list_page_with_long_title
    title = 'VeryLongTitleWithNoSpaceThatWillBeFarTooLongToFitIntoTheTableColumnAndInTurnBreakTheLayoutUnlessItIsBrokenUsingHiddenHyphens'
    expected = 'VeryLongTitleWithNoS&shy;paceThatWillBeFarToo&shy;LongToFitIntoTheTabl&shy;eColumnAndInTurnBrea&shy;kTheLayoutUnlessItIs&shy;BrokenUsingHiddenHyp&shy;hens'
    page = FactoryGirl.build :wiki_page, :title => title, :owner => users(:blue)
    Page.expects(:paginate_by_path).returns([page])
    login_as users(:blue)
    xhr :get, :index
    assert_response :success
    assert assigns(:pages).include?(page)
    assert response.body.include?(expected), "Expected #{response.body} to include #{expected}."
  end

end
