require 'test_helper'

class GalleryControllerTest < ActionController::TestCase
  fixtures :pages, :users

  def setup
    # let's make some gallery
    # there are no galleries in fixtures yet.
    #
    @gallery = Gallery.create! :title => 'gimme pictures', :user => users(:blue)
    @asset = @gallery.add_image! :uploaded_data => upload_data('photo.jpg')
    users(:blue).updated(@gallery)
  end

  def test_show
    login_as :blue
    get :show, :page_id => @gallery.id
    assert_response :success
    assert_not_nil assigns(:images)
  end

  def test_show_empty
    login_as :blue
    gallery = Gallery.create!( :user => users(:blue),
      :title => "Empty Gallery")
    get :show, :page_id => gallery.id
    assert_response :redirect
    assert_redirected_to @controller.send(:page_url, gallery, :action => 'edit')
  end

  def test_edit
    login_as :blue
    get :edit, :page_id => @gallery.id
    assert_response :success
  end

  def test_update
    # we need two images
    @asset2 = Asset.create_from_params({
      :uploaded_data => upload_data('photo.jpg')}) do |asset|
        asset.parent_page = @gallery
      end
    @gallery.add_image!(@asset2, users(:blue))
    @asset2.save!
    login_as :blue
    xhr :post, :update, :page_id => Gallery.find(:first).id,
      :sort_gallery => [@asset2.id, @asset.id]
    assert_response :success
    assert_equal [@asset2.id, @asset.id], @gallery.reload.images.map(&:id)
  end

end
