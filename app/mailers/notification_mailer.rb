class NotificationMailer < BaseMailer

  def send_contact_details(data)
    @contact_details = data

    mail to: ENV["SUPPORT_MAIL"], cc: ENV["ADMIN"]
  end

end
