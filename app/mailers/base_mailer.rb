class BaseMailer < ActionMailer::Base
  include AMQPQueue::Mailer

  layout 'mailers/application'
  helper MailerHelper

  default from: "Axioex Support <#{ENV['SYSTEM_MAIL_FROM']}>",
          reply_to: ENV['SUPPORT_MAIL']
end
