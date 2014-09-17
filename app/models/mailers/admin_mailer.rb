class AdminMailer < Mailer
  def blast(user, options)
    setup(options)
    setup_user(user)
    @subject += options[:subject]
    @message = options[:body]
  end


  def notify_inappropriate(user, options)
    setup(options)
    setup_user(user)
    @subject += "Inappropriate Content"
    @message = options[:body]
    @url = link(options[:url])
    @owner = options[:owner]
  end

  protected

  def setup_user(user)
    @recipients = "#{user.email}"
    @from       = @from_address
    @subject    = @site.title + ": "
    @user       = user
  end

end
