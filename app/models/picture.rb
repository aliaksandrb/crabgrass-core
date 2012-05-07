#
# Picture -- a simple record to hold a single image file.
#
# We have three models that handle image files: Asset, Avatar, and
# Picture. Why so many? They are each pretty different.
#
#   Asset   -- for when you need versioning and thumbnails
#              of any content type.
#              Permissions: YES
#
#   Avatar  -- for square icons of users and groups.
#              Permissions: NO
#
#   Picture -- when you want a simple image and want to be able to
#              display it with many sizing options.
#              Permissions: maybe eventually.
#
# GEOMETRY
#
# A "geometry", for the purposes of Pictures, is an object with the
# following attributes:
#
#  min_width,  max_width
#  min_height, max_height
#
# All the attributes are optional. Attributes with a zero value
# become nil. Any method that accepts geometry argument will also
# take nil, which represents the unresized original image.
#
# Geometry.new will take three input forms:
#
# (1) Hash, like {:min_width => 50}
# (2) Array, like [50,0,0,0]
# (3) String, like "50-0-0-0"
#
# STORAGE
#
# Picture.dimensions stores, in a hash, the height and width of all
# the resized copies of the image, keyed on the geometry constraints
# that produced the resized copy.
#
# For example:
#
#  { [a,b,c,d] => [width, height],
#    [a,b,c,d] => [width, height] }
#
# where a,b,c,d is the value of:
#
#  min_width, max_width, min_height, max_height
#
# Suppose picture.dimensions looks like this:
#
#  {'full' => [256,256], [100,100,0,400] => [100,400]}
#
# This corresponds to files stored like so:
#
#  0000/0004/full.jpg
#  0000/0004/100-100-0-400.jpg
#
# The values are integers, and not strings.
#
# TODO: graceful handling of corrupted images
#

require 'open-uri'     # required for open(url).read
require 'fileutils'    # required for mkdir and rmdir
require 'pathname'     # required for relative paths

MAX_HEIGHT = 1024
MAX_WIDTH = 1024

class Picture < ActiveRecord::Base

  URL_ROOT = PICTURE_PUBLIC_STORAGE.sub(File.join(Rails.root,'public'),'')

  serialize :dimensions
  after_destroy :destroy_files
  after_create :save_uploaded_file

  #
  # the private filesystem path of this picture
  # e.g. rails_root/assets/pictures/0000/0004/full.jpg
  #
  def private_file_path(geometry=nil)
    geometry = to_geometry(geometry)
    File.join(private_directory, file_name(geometry))
  end

  #
  # the public filesystem path of this picture
  #
  def public_file_path(geometry=nil)
    geometry = to_geometry(geometry)
    File.join(public_directory, file_name(geometry))
  end

  #
  # the relative url path for this picture
  #
  def url(geometry=nil)
    geometry = to_geometry(geometry)
    File.join(URL_ROOT, directory, file_name(geometry))
  end

  #
  # returns [width, height] for a given geometry
  #
  def size(geometry=nil)
    geometry = to_geometry(geometry)
    dimensions[geometry.to_s] ||= file_dimensions(private_file_path(geometry))
  end

  #
  # Adds a new geometry definition to this Picture, and saves
  # a copy of the resized image.
  #
  # You must add a geometry definition before you can display
  # a picture resized to a given dimensions.
  #
  def add_geometry!(geometry)
    geometry = to_geometry(geometry)
    if geometry.any?
      geo_key = geometry.to_s
      self.dimensions ||= {}
      if dimensions[geo_key].nil?
        resize(geometry, private_file_path, private_file_path(geometry))
        width, height = file_dimensions( private_file_path(geometry) )
        self.dimensions[geo_key] = [width,height]
        save!
      end
    end
  end

  #
  # removes a geometry from this picture, and the associated image files
  #
  def remove_geometry!(geometry)
    geometry = to_geometry(geometry)
    if geometry.any?
      geo_key = geometry.to_s
      self.dimensions ||= {}
      if dimensions[geo_key].any?
        destroy_file(geometry)
        dimensions.delete(geo_key)
        save!
      end
    end
  end

  #
  # This method does three things:
  # (1) Adds the geometry to this picture's list of dimensions
  # (2) Creates the public and private storage directories for this picture.
  # (3) Renders the image matching geometry
  #
  # If any of those things exists or are already set up, this method
  # skips it.
  #
  def render!(geometry)
    geometry = to_geometry(geometry)
    # ensure dimension record exists
    add_geometry!(geometry)
    render(geometry)
  end

  #
  # like render!, but will not add a new geometry
  #
  def render(geometry)
    geometry = to_geometry(geometry)
    # ensure the file has been rendered
    unless File.exists?(private_file_path(geometry))
      resize(geometry, private_file_path, private_file_path(geometry))
    end
    # ensure symlink to public dir exists
    add_symlink # for now, all Pictures are public.
  end

  #
  # for uploading the image.
  #
  # The uploaded_file may be one of three types:
  #
  # (1) an empty String  (if form was empty)
  # (2) UploadedStringIO (if the file is small)
  # (3) UploadedTempfile (if file is big)
  #
  def upload=(uploaded_file)
    return if uploaded_file.is_a?(String) and uploaded_file.empty?
    return if uploaded_file.original_filename.empty?

    @uploaded_file = uploaded_file
    self.content_type = uploaded_file.content_type ||
      Media::MimeType.mime_type_from_extension(uploaded_file.original_filename)
  end

  #
  # Convert geometry specified as Hash, Array, or String into Geometry.
  #
  def to_geometry(geometry)
    if geometry.is_a? Geometry
      return geometry
    elsif geometry.nil?
      return Geometry.new
    elsif geometry.is_a? Hash
      a = geometry[:min_width]
      b = geometry[:max_width]
      c = geometry[:min_height]
      d = geometry[:max_height]
    elsif geometry.is_a? Array
      a, b, c, d = geometry
    elsif geometry.is_a? String
      a, b, c, d = geometry.split('-')
    end
    return Geometry.new(a,b,c,d)
  end

  #
  # Picture::Geometry class
  #
  # We ensure that the attributes consists only of integers or nil.
  # This is important, because we might have got the geometry source
  # from a url.
  #
  class Geometry

    attr_accessor :min_width, :max_width, :min_height, :max_height

    def initialize(minw=nil, maxw=nil, minh=nil, maxh=nil)
      self.min_width  = minw.to_i if minw
      self.min_width  = nil       if self.min_width == 0
      self.max_width  = maxw.to_i if maxw
      self.max_width  = nil       if self.max_width == 0
      self.min_height = minh.to_i if minh
      self.min_height = nil       if self.min_height == 0
      self.max_height = maxh.to_i if maxh
      self.max_height = nil       if self.max_height == 0
    end

    def empty?
      not any?
    end

    def any?
      min_width or max_width or min_height or max_height
    end

    def to_s
      empty? ? 'full' : to_a.join('-')
    end

    def to_a
      empty? ? [] : [min_width||0, max_width||0, min_height||0, max_height||0]
    end

  end


  ##
  ## PRIVATE METHODS
  ##

  private

  #
  # after_create callback.
  #
  # We wait until after the Picture is created to actually capture
  # and store the uploaded file. Otherwise, we end up saving files
  # even for pictures we never save.
  #
  def save_uploaded_file
    allocate_storage_directory
    File.open(private_file_path, "wb") do |f|
      f.write(@uploaded_file.read)
    end
    # save the height & width for the 'full' image (indexed as 'full' in geometry hash)
    add_geometry! nil
  end

  #
  # the relative path of the directory where all the files live for
  # this picture. (returned as an array for use in File.join)
  #
  # e.g. id of 12345 produces ['0001','2345']
  #
  def directory
    ("%08d" % id).scan(/..../)
  end

  #
  # the private filesystem path of this picture
  #
  def private_directory
    File.join(PICTURE_PRIVATE_STORAGE, directory)
  end

  #
  # the public filesystem path of this picture
  #
  def public_directory
    File.join(PICTURE_PUBLIC_STORAGE, directory)
  end

  #
  # returns a file name appropriate for the specified
  # geometry.
  #
  # eg:
  #   {:max_height => 100}  --> '0-0-0-100.jpg'
  #   nil                   --> 'full.jpg'
  #
  #
  def file_name(geometry=nil)
     if geometry
       geometry.to_s + '.' + ext
     else
       'full.' + ext
     end
  end

  #
  # returns the file extension suitable for this content_type
  #
  def ext
    Media::MimeType.extension_from_mime_type(content_type).to_s
  end

  #
  # Destroys the all files for this picture
  #
  def destroy_files
    FileUtils.rm_rf(private_directory) if File.exists?(private_directory)
    FileUtils.rm(public_directory) if File.exists?(public_directory)
  end

  #
  # Destroys a single rendered file
  #
  def destroy_file(geometry)
    FileUtils.rm(public_file_path(geometry))
    FileUtils.rm(private_file_path(geometry))
  end

  #
  # Ensures storage directory exists for this Picture
  #
  def allocate_storage_directory
    FileUtils.mkdir_p(private_directory) unless File.exists?(private_directory)
    add_symlink # for now, all Pictures are public.
  end

  #
  # creates a symlink from the private storage to a public storage
  #
  # this makes the picture public
  #
  def add_symlink
    unless File.exists?(public_directory)

      public_directory_parent = File.dirname(public_directory)
      unless File.exists?(public_directory_parent)
        FileUtils.mkdir_p(public_directory_parent)
      end

      real_private_path = Pathname.new(private_directory).realpath
      real_public_path  = Pathname.new(public_directory_parent).realpath
      public_to_private = real_private_path.relative_path_from(real_public_path)
      FileUtils.ln_s(public_to_private, real_public_path)
    end
  end

  #
  # removes symlink that links private and public directories
  #
  # this makes the picture private.
  #
  def remove_symlink
    if File.exists?(public_directory)
      FileUtils.rm(public_directory)
    end
  end

  #
  # render a new file with the specified geometry
  #
  def resize(geometry, input_file, output_file)
    status = GraphicsMagickTransmogrifier.new(
      :input_file => input_file,
      :output_file => output_file,
      :size => geometry_to_size(geometry),
      :crop => geometry_to_crop(geometry)
    ).try.run
    if status != :success
      raise ErrorMessage.new('invalid image')
    end
  end

  #
  # Convert geometry definition into graphic magick compatible
  # resize options. The logic is complicated, but it tries
  # to do the right thing.
  #
  # summary from gm man page on -geometry:
  #
  #   1. WxH  -- max dimensions, resize with aspect ratio intact
  #   2. WxH^ -- min dimensions, resize with aspect ratio intact
  #   3. WxH! -- force dimensions exactly
  #   4. Wx   -- resize, maintain ratio, auto set height
  #   5. xH   -- resize, maintain ratio, auto set width
  #   6. WxH> -- shrink if bigger (W or H)
  #   7. WxH< -- expand if smaller (W and H)
  #
  def geometry_to_size(geometry)
    width, height = size()
    scale_width = nil
    scale_height = nil
    new_width = nil
    new_height = nil

    # scale width?
    if geometry.min_width && width < geometry.min_width
      scale_width = geometry.min_width.to_f / width   # scale bigger
      new_width = geometry.min_width
    elsif geometry.max_width && width > geometry.max_width
      scale_width = geometry.max_width.to_f / width   # scale smaller
      new_width = geometry.max_width
    end

    # scale height?
    if geometry.min_height && height < geometry.min_height
      scale_height = geometry.min_height.to_f / height  # scale bigger
      new_height = geometry.min_height
    elsif geometry.max_height && height > geometry.max_height
      scale_height = geometry.max_height.to_f / height  # scale smaller
      new_height = geometry.max_height
    end

    # scale in both dimensions
    if scale_width && scale_height
      # if scale both bigger
      if scale_width > 1 && scale_height > 1
        # scale by one that needs to grow more
        if scale_width > scale_height
          "%sx^" % new_width   # bigger
        else
          "x%s^" % new_height  # bigger
        end
      # if scale both smaller
      elsif scale_width < 1 && scale_height < 1
        # scale by one that needs to shrink the least
        if scale_width > scale_height
          "%sx" % new_width  # smaller
        else
          "x%s" % new_height # smaller
        end
      # if scale width bigger AND scale height smaller
      elsif scale_width > 1
        "%sx^" % new_width  # bigger
      # if scale height bigger AND scale width smaller
      elsif scale_height > 1
        "x%s^" % new_height # bigger
      end
    # scale in one dimension
    elsif scale_width
      if scale_width > 1
        "%sx^" % new_width # bigger
      else
        "%sx" % new_width  # smaller
      end
    elsif scale_height
      if scale_height > 1
        "x%s^" % new_height # bigger
      else
        "x%s" % new_height  # smaller
      end
    end
  end

  def geometry_to_crop(geometry)
    if geometry.max_width or geometry.max_height
      "%sx%s" % [geometry.max_width||10000000, geometry.max_height||10000000]
    else
      nil
    end
  end

  #
  # returns [width,height] of the specified image file
  #
  def file_dimensions(file_path)
    width, height = GraphicsMagickTransmogrifier.new.dimensions(file_path)
    [(width||0).to_i, (height||0).to_i]
  end

end


