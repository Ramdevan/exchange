class MemberMailer < BaseMailer

  def notify_signin(member_id)
    set_mail(member_id)
  end

  def google_auth_activated(member_id)
    set_mail(member_id)
  end

  def google_auth_deactivated(member_id)
    set_mail(member_id)
  end

  def sms_auth_activated(member_id)
    set_mail(member_id)
  end

  def sms_auth_deactivated(member_id)
    set_mail(member_id)
  end

  def reset_password_done(member_id)
    set_mail(member_id)
  end

  def phone_number_verified(member_id)
    set_mail(member_id)
  end

  def kyc_status(member_id)
    @member = Member.find member_id
    @message = @member.id_document.note
    mail to: @member.email, subject: t('.subject'), status: (@member.id_document.aasm_state.camelize)
  end

  private

  def set_mail(member_id)
    @member = Member.find member_id
    mail to: @member.email
  end
end
