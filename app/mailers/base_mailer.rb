class BaseMailer < ActionMailer::Base
  include AMQPQueue::Mailer

  layout 'mailers/application'
  add_template_helper MailerHelper

  default from: "Citioption Support <#{ENV['SYSTEM_MAIL_FROM']}>",
          reply_to: ENV['SUPPORT_MAIL']
end
