require 'tempfile'
require 'ftools'
require 'pathname'

Tempfile.class_eval do
  #
  # overwrite so that Tempfile will retain the file extension of the basename.
  #
  def make_tmpname(basename, n)
    ext = nil
    sprintf("%s%d-%d%s", basename.to_s.gsub(/\.\w+$/) { |s| ext = s; '' }, $$, n, ext)
  end
end

#
# media processing requires a different type of tempfile... because we use command
# line tools to process our temp files, these files can't be open and closed by ruby.
#
# instead, Media::TempFile is used to generate closed files from binary data (for files
# to be fed to command line tools), or to generate empty tmp files (for output filenames
# to be fed to command line tools).
#
# We use the Tempfile class for generating these files, but then we always close them
# right away. By doing this, we ensure that the temp file will eventually get removed
# when the Tempfile gets garbage collected.
#

module Media
  class TempFile

    @@tempfile_path = File.join(RAILS_ROOT, 'tmp', 'processing')
    cattr_accessor :tempfile_path

    ##
    ## INSTANCE METHODS
    ##

    public

    # 
    # file data may be one of:
    # 
    #  - Pathname object: then load data from the file pointed to by the pathname.
    #  - IO object: read the contents of the io object, copy to tmp file.
    #  - otherwise, dump the contents of the data to the tmp file.
    #
    # if data is empty, we generate an empty one.
    #
    def initialize(data, content_type=nil)
      if data.nil?
        @tmpfile = TempFile.create_from_content_type(content_type)
      elsif data.is_a?(StringIO)
        data.rewind
        @tmpfile = TempFile.create_from_data(data.read, content_type)
      elsif data.instance_of?(Pathname)
        @tmpfile = TempFile.create_from_file(data.to_s)
      else
        @tmpfile = TempFile.create_from_data(data, content_type)
      end
    end

    #
    # like initialize, but if given a block, then it yields the TempFile
    # and also unlinks the file at the end of the block.
    #
    def self.open(data, content_type=nil)
      tmp = TempFile.new(data, content_type)
      if block_given?
        begin
          yield tmp
        ensure
          tmp.clear
        end
        nil
      else
        tmp
      end
    end

    def clear
      # disable this to debug the files in their various states...
      @tmpfile.unlink
    end

    def any?
      @tmpfile.any?
    end

    def path
      @tmpfile.path
    end

    def to_s
      @tmpfile.path
    end

    ##
    ## CLASS METHODS
    ##

    private

    #
    # creates a tempfile filled with the given binary data
    #
    def self.create_from_data(data, content_type=nil)
      returning Tempfile.new(content_type_basename(content_type), @@tempfile_path) do |tmp|
        tmp.binmode
        tmp.write(data)
        tmp.close
      end
    end

    #
    # create an empty temp file with an extension to match the content_type
    #
    def self.create_from_content_type(content_type)
      returning Tempfile.new(content_type_basename(content_type), @@tempfile_path) do |tmp|
        tmp.close
      end
    end

    #
    # create a tmp file that is a copy of another file.
    #
    def self.create_from_file(filepath)
      returning Tempfile.new(File.basename(filepath), @@tempfile_path) do |tmp|
        tmp.close
        FileUtils.cp filepath, tmp.path
      end
    end

    # 
    # create a type file basename with a file extension from the content_type
    # (new method)
    #
    def self.content_type_basename(content_type)
      if content_type
       "%s.%s" % ['media_temp_file', Media::MimeType.extension_from_mime_type(content_type)]
      else
        'media_temp_file'
      end
    end

  end
end

FileUtils.mkdir_p(Media::TempFile.tempfile_path) unless File.exists?(Media::TempFile.tempfile_path)

