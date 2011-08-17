module Common::Utility::GeneralHelper

  ##
  ## GENERAL UTILITY
  ##

  # returns the first of the args where any? returns true
  # if none has any, return last
  def first_with_any(*args)
    for str in args
      return str if str.any?
    end
    return args.last
  end

  ## converts bytes into something more readable
  def friendly_size(bytes)
    return unless bytes
    if bytes > 1.megabyte
      '%s MB' % (bytes / 1.megabyte)
    elsif bytes > 1.kilobyte
      '%s KB' % (bytes / 1.kilobyte)
    else
      '%s B' % bytes
    end
  end

  def once?(key)
    @called_before ||= {}
    return false if @called_before[key]
    @called_before[key]=true
  end

  # used to set the class 'first' for lists of things, because css selector :first
  # is not very reliable.
  def first(key)
    once?(key) ? 'first' : ''
  end

  def logged_in_since
    session[:logged_in_since] || Time.now
  end

  # calls 'call' on proc if it really is a proc.
  def safe_call(proc, *args)
    if proc.is_a? Proc
      proc.call(*args)
    else
      proc
    end
  end

  # from http://www.igvita.com/2007/03/15/block-helpers-and-dry-views-in-rails/
  # Only need this helper once, it will provide an interface to convert a block into a partial.
  # 1. Capture is a Rails helper which will 'capture' the output of a block into a variable
  # 2. Merge the 'body' variable into our options hash
  # 3. Render the partial with the given options hash. Just like calling the partial directly.
  def block_to_partial(partial_name, options = {}, &block)
    options.merge!(:body => capture(&block))
    concat(render(:partial => partial_name, :locals => options))
  end

  def browser_is_ie?
    user_agent = request.env['HTTP_USER_AGENT'].try.downcase
    user_agent =~ /msie/ and user_agent !~ /opera/
  end

end
