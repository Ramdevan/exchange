class Adminmailer < ApplicationMailer
    default to:"support@citioption.com"
    def admin_email(mail,name,subject,body)
    
        subject="#{name}-#{subject}"
        mail(from: mail, subject: subject,body: body )
      end
    def activation1(user,ip,check_id)
      @user=user
      @ip=ip
      @check_id=check_id
      mail(from: "coinage@cloud.com",subject:"this is activation link")
    end
end
