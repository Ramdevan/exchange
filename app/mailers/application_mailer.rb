class ApplicationMailer < ActionMailer::Base
  default from: ENV["SYSTEM_MAIL_FROM"]
  layout 'mailer'
end
