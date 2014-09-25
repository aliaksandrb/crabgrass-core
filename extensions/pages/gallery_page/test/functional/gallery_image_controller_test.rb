require 'test_helper'

class GalleryImageControllerTest < ActionController::TestCase
  fixtures :pages, :users, :groups, :memberships

  def setup
    # let's make some gallery
    # there are no galleries in fixtures yet.
    #
    @gallery = Gallery.create! :title => 'gimme pictures', :user => users(:blue)
    @asset = Asset.create_from_params({
      :uploaded_data => upload_data('photo.jpg')}) do |asset|
        asset.parent_page = @gallery
      end
    @gallery.add_image!(@asset, users(:blue))
    @gallery.save!
    @asset.save!
  end

  def test_may_not_edit
    @gallery.add(groups(:rainbow), :access => :view).save!
    @gallery.save!
    login_as :red
    xhr :get, :edit, :id => @asset.id, :page_id => @gallery.id
    assert_permission_denied
  end

  def test_may_edit
    skip "we currently do not allow editing images"
    @gallery.add(groups(:rainbow), :access => :edit).save!
    @gallery.save!
    login_as :red
    xhr :get, :edit, :id => @asset.id, :page_id => @gallery.id
    assert_response :success
    assert assigns(:image)
    assert_equal assigns(:image).id, @asset.id
    assert assigns(:image).caption.blank?
  end

  def test_may_not_update_caption
    @gallery.add(groups(:rainbow), :access => :view).save!
    @gallery.save!
    login_as :red
    post :update, :page_id => @gallery.id, :id => @asset.id,
      :caption => 'New Title'
    assert_permission_denied
    assert @asset.reload.caption.blank?
  end

  def test_may_update_caption
    @gallery.add(groups(:rainbow), :access => :edit).save!
    @gallery.save!
    login_as :red
    post :update, :page_id => @gallery.id, :id => @asset.id,
      :image => {:caption => 'New Title' }
    assert_response :redirect
    assert_equal 'New Title',  @asset.reload.caption
  end

  def test_update_cover
    skip "we currently do not allow updating the gallery cover"
    @gallery.add(groups(:rainbow), :access => :edit).save!
    @gallery.save!
    login_as :red
    post :update, :page_id => @gallery.id, :id => @asset.id,
      :image => {:cover => true }
    assert_response :redirect
    assert_equal @asset, @gallery.reload.cover
  end

  def test_show
    login_as :blue
    assert @asset.id, "image should not be nil"
    xhr :get, :show, :id => @asset.id, :page_id => @gallery.id
    assert_response :success
    assert assigns(:showing)
  end

  def test_may_not_show
    login_as :red
    xhr :get, :show, :id => @asset.id, :page_id => @gallery.id
    assert_permission_denied
  end

  def test_may_show
    @gallery.add(groups(:rainbow), :access => :view).save!
    @gallery.save!
    login_as :red
    xhr :get, :show, :id => @asset.id, :page_id => @gallery.id
    assert_response :success
    assert assigns(:showing)
  end

  def test_may_upload
    login_as :blue
    xhr :put, :update, :id => @asset.id, :page_id => @gallery.id,
        :assets => [upload_data('photo.jpg')]
    assert_response :success
  end

  def test_can_change_file_type
    login_as :blue
    xhr :put, :update, :id => @asset.id, :page_id => @gallery.id,
        :assets => [upload_data('cc.gif')]
    assert_response :success
  end

end
