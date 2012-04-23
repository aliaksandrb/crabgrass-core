require File.dirname(__FILE__) + '/../../test_helper'

class Groups::StructuresControllerTest < ActionController::TestCase

  def setup
    @user = User.make
    @group = Group.make
    @group.add_user! @user
  end


  def test_new_committee
    login_as @user
    assert_permission :may_edit_group_structure? do
      get :new,
        :group_id => @group.to_param,
        :type => 'committee'
    end
    assert_response :success
  end

  def test_create_committee
    login_as @user
    assert_permission :may_edit_group_structure? do
      assert_difference '@group.committees.count' do
        get :create,
          :group_id => @group.to_param,
          :type => 'committee',
          :committee => Committee.plan
      end
    end
    assert_response :redirect
  end

  def test_new_council
    login_as @user
    assert_permission :may_edit_group_structure? do
      get :new,
        :group_id => @group.to_param,
        :type => 'council'
    end
    assert_response :success
  end

  def test_create
    login_as @user
    assert_permission :may_edit_group_structure? do
      assert_difference '@group.committees.count' do
        get :create,
          :group_id => @group.to_param,
          :council => Council.plan,
          :type => 'council'
      end
    end
    assert_response :redirect
  end
end
