require File.dirname(__FILE__) + '/../../test_helper'

class Wikis::SectionsControllerTest < ActionController::TestCase

  def setup
    @user = User.make
    @group = Group.make
    @group.add_user!(@user)
    @wiki = @group.profiles.public.create_wiki :body => <<-EOB
h2. section one

one

h3. section one A

one A

h2. section two

two

h1. big section

biggie
    EOB
  end


  def test_edit
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :get, :edit, :wiki_id => @wiki.id, :id => 'section-one'
    end
    assert_response :success
    assert_template 'wikis/sections/edit.rjs'
    markup = <<-EOM
h2. section one

one

h3. section one A

one A

    EOM
    assert_equal markup, assigns['markup']
    assert_equal 'section-one', assigns['section']
    assert_equal @wiki, assigns['wiki']
    assert_equal @group, assigns['context'].entity
    assert_equal @user, @wiki.reload.locker_of('section-one')
  end

  def test_edit_locked
    other_user = User.make
    @wiki.lock! :document, other_user
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :get, :edit, :wiki_id => @wiki.id, :id => 'section-one'
    end
    assert_response :success
    assert_template 'wikis/sections/locked.rjs'
    assert_equal other_user, @wiki.locker_of(:document)
    assert_equal @wiki, assigns['wiki']
  end

  def test_update
    login_as @user
    assert_permission :may_edit_wiki? do
      xhr :post, :update,
        :wiki_id => @wiki.id, :id => 'section-one',
        :wiki => {:body => '*updated*', :version => 1}
    end
    assert_response :redirect
    assert_redirected_to group_wiki_url(@group, @wiki)
    changed_body = <<-EOB
*updated*

h2. section two

two

h1. big section

biggie
    EOB
    assert_equal changed_body, @wiki.reload.body
  end

end
