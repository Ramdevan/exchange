class Adminmailer < ApplicationMailer
  default from: ENV["SYSTEM_MAIL_FROM"],
          to:   ENV["SYSTEM_MAIL_TO"]

  def admin_email(mail, name, subject, body)
    subject = "#{name}-#{subject}"
    mail(from: mail, subject: subject, body: body)
  end

  def activation1(user, ip, check_id)
    @user = user
    @ip = ip
    @check_id = check_id
    mail subject: "this is activation link"
  end
end
