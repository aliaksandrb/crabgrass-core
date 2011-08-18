#
#  create_table "thumbnails", :force => true do |t|
#    t.integer "parent_id",    :limit => 11
#    t.string  "parent_type"
#    t.string  "content_type"
#    t.string  "filename"
#    t.string  "name"
#    t.integer "size",         :limit => 11
#    t.integer "width",        :limit => 11
#    t.integer "height",       :limit => 11
#    t.integer "job_id",
#    t.boolean "failure"
#  end
#

require 'open-uri'

class Thumbnail < ActiveRecord::Base

  #
  # Our parent could be the main asset, or it could be a *version* of the
  # asset.
  # If we are a thumbnail of the main asset:
  #   self.parent_id = id of asset
  #   self.parent_type = "Asset"
  # If we are the thumbnail of an asset version:
  #   self.parent_id = id of the version
  #   self.parent_type = "Asset::Version"
  #
  belongs_to :parent, :polymorphic => true

  belongs_to :remote_job, :dependent => :destroy

  after_destroy :rm_file
  def rm_file
    unless proxy?
      fname = parent.private_thumbnail_filename(filename)
      FileUtils.rm(fname) if File.exists?(fname) and File.file?(fname)
    end
  end

  # returns the thumbnail object that we depend on, if any.
  def depends_on
    @depends ||= parent.thumbnail(thumbdef.depends, true)
  end

  # finds or initializes a Thumbnail
  def self.find_or_init(thumbnail_name, parent_id, asset_class)
    self.find_or_initialize_by_name_and_parent_id_and_parent_type(
      thumbnail_name.to_s, parent_id, asset_class
    )
  end

  #
  # generates the thumbnail file for this thumbnail object.
  #
  # if force is true, then generate the thumbnail even if it already
  # exists.
  # 
  def generate(force=false)
    if proxy?
      return
    elsif !force and File.exists?(private_filename) and File.size(private_filename) > 0
      return
    else
      if depends_on
        depends_on.generate(force)
        source = depends_on.parent
      else
        source = parent
      end

      input_type  = source.content_type
      input_file  = source.private_filename
      output_type = thumbdef.mime_type
      output_file = private_filename

      options = {
        :size => thumbdef.size,
        :input_file  => input_file,  :input_type => input_type, 
        :output_file => output_file, :output_type => output_type,
        :source_asset => source
      }

      if thumbdef.remote and RemoteJob.site
        queue_remote_job(options)
      else
        generate_now(options)
      end
      save if changed?
    end
  end

  def versioned
    if !parent.is_version?
      asset = parent.versions.detect{|v|v.version == parent.version}
      asset.thumbnail(self.name) if asset
    end
  end

  def small_icon
    "mime/small/#{Media::MimeType.icon_for(content_type)}"
  end

  def title
    thumbdef.title || Media::MimeType.description_from_mime_type(content_type)
  end

  # delegate path stuff to the parent
  def private_filename
    parent.private_thumbnail_filename(self.name)
  end

  def public_filename
    parent.public_thumbnail_filename(self.name)
  end

  def url
    parent.thumbnail_url(self.name)
  end

  def exists?
    parent.thumbnail_exists?(self.name)
  end

  def thumbdef
    parent.thumbdefs[self.name.to_sym]
  end

  def ok?
    not failure?
  end

  def set_data_from_url(url)
    data = open(@job.data_url).read
    File.open(private_filename, "wb") do |f|
      f.write(data)
    end
  end

  #
  # returns true if this thumbnail is a proxy AND
  # the main asset file is the same content type as
  # this thumbnail.
  #
  # when true, we skip all processing of this thumbnail
  # and just proxy to the main asset.
  #
  # For example, in the DocAsset, if the uploaded file is a microsoft word
  # file, then we first convert it to a libreoffice document before converting
  # to a pdf. However, If the uploaded file is already libreoffice, then
  # the libreoffice thumbnail is just proxied to the original uploaded file.
  #
  # This seems messy to me, there is probably a cleaner way.
  #
  def proxy?
    thumbdef.proxy and parent.content_type == thumbdef.mime_type
  end

  private

  def queue_remote_job(options)
    if !RemoteJob.local?
      if thumbdef.binary
        options[:input_url] = options[:source].url_with_code
      else
        # if we don't have binary data, then we might as well pass it along
        options[:input_data] = File.read(options[:input_file])
      end
      # the remote processor is on another server, so we don't pass it file paths
      options[:input_file] = nil
      options[:output_file] = nil
    end
    options[:success_callback_url] = self.success_url
    self.remote_job = RemoteJob.create!(options)
    unless remote_job
      self.failure = true
    end
    save
  end

  def generate_now(options)
    trans = Media.transmogrifier(options)
    if trans.run() == :success
      update_metadata(options)
      self.failure = false
    else
      # failure
      self.failure = true
    end
    save if changed?
  end

  def update_metadata(options)
    # dimensions
    if Media.has_dimensions?(options[:output_type]) and thumbdef.size.present?
      self.width, self.height = Media.dimensions(options[:output_file])
    end
    # size
    self.size = File.size(options[:output_file])

    # by the time we figure out what the thumbnail dimensions are,
    # the duplicate thumbnails for the version have already been created.
    # so, when our dimensions change, update the versioned thumb as well.
    if (vthumb = versioned()).any?
      vthumb.width, vthumb.height = [self.width, self.height]
      vthumb.save
    end
  end

  def success_url
    "/thumbnails/#{id}?status=success"
  end

end

