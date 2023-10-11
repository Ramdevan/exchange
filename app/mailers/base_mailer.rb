class BaseMailer < ActionMailer::Base
  include AMQPQueue::Mailer

  layout 'mailers/application'
  add_template_helper MailerHelper

  default from: "Axios Support <#{ENV['SYSTEM_MAIL_FROM']}>",
          reply_to: ENV['SUPPORT_MAIL']
end
