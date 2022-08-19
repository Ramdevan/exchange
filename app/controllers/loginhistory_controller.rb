class LoginhistoryController < ApplicationController

  def show_history
    @login = Loginhistory.where(member_id: current_user.id).order(created_at: :desc)
    @login = @login.page(params[:page]).per(20)
  end

  def verify_token
    if @member_id = Whitelisting.find_by(token: params[:token])
      if @member_id.expired_at > Time.zone.now
        @member_id.authorised_ip = true
        @member_id.save
        redirect_to signin_path, alert: t('.ip_verified')
      else
        redirect_to signin_path, alert: t('.captcha_expired')
      end
    else
      redirect_to signin_path, alert: t('.invalid_token')
    end
  end
end
