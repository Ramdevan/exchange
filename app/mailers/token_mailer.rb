class TokenMailer < BaseMailer

  def reset_password(email, token)
    @token_url = edit_reset_password_url(token)
    @member = Member.find_by_email(email)
    mail to: email
  end

  def activation(email, token)
    @token_url = edit_activation_url token
    @member = Member.find_by_email(email)
    mail to: email
  end

end
