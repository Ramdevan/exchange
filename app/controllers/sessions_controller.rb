class SessionsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:create]

  before_action :auth_member!, only: [:destroy]
  before_action :auth_anybody!, only: [:new, :failure]

  helper_method :require_captcha?

  def new
    @identity = Identity.new
    render layout: 'empty'
  end

  def create
    @member = Member.from_auth(auth_hash, set_options)
    # ip_whitelist = Whitelisting.find_by(member_id: @member.id, ip_address: request.ip).first
    # if ip_whitelist && ip_whitelist.authorised_ip?
    #   @token = SecureRandom.hex(16)
    #   hash = {'token' => "#{@token}"}
    #   Adminmailer.activation1(hash, request.ip, ip_whitelist).deliver_now
    #   if ip_whitelist
    #     check_auth_ip @member.id, @token
    #     redirect_to signin_path, alert: t('.verify_ip')
    #   else
    #     save_ip = Whitelisting.find_by(member_id: @member.id, ip_address: request.ip)
    #     save_ip.update(token: @token)
    #     save_ip.update(expired_at: Time.zone.now + 60)
    #     respond_to do |format|
    #       format.html { redirect_to request.referer, alert: t('.verify_ip') }
    #     end
    #   end
    # else
      if @member
        if @member.disabled?
          increase_failed_logins
          redirect_to signin_path, alert: t('.disabled')
        else
          clear_failed_logins
          reset_session rescue nil
          session[:member_id] = @member.id
          save_session_key @member.id, cookies['_exchange_session']
          save_signup_history @member.id

          country = Geocoder.search("#{request.ip}").first.country
          user_agent_string = request.headers["User-Agent"]
          user_agent = ::UserAgent.parse(user_agent_string)
          save_login_history @member.id, country, user_agent
          if @member.activated?
            MemberMailer.notify_signin(@member.id).deliver!
            redirect_back_or_settings_page
          else
            redirect_to settings_path
          end
        end
      else
        increase_failed_logins
        redirect_to signin_path, alert: (error || t('.error'))
      end
    # end
  end

  def failure
    increase_failed_logins
    redirect_to signin_path, alert: t('.error')
  end

  def destroy
    clear_all_sessions current_user.id
    reset_session
    redirect_to root_path
  end

  def sendmail
    mail = params[:contactEmail]
    fname = params[:name]
    subject = params[:subject]
    message = params[:comment]
    Adminmailer.admin_email(mail, fname, subject, message).deliver_now
    respond_to do |format|
      format.html { redirect_to request.referer, alert: t('.Mail_sent') }
    end

  end

  def show
  end

  def fee
    @fee = Currency.all_fee_details
  end

  private


  def require_captcha?
    failed_logins > 3
  end

  def failed_logins
    Rails.cache.read(failed_login_key) || 0
  end

  def increase_failed_logins
    Rails.cache.write(failed_login_key, failed_logins + 1)
  end

  def clear_failed_logins
    Rails.cache.delete failed_login_key
  end

  def failed_login_key
    "axios:session:#{request.ip}:failed_logins"
  end

  def auth_hash
    @auth_hash ||= env["omniauth.auth"]
  end

  def save_signup_history(member_id)
    SignupHistory.create(
      member_id: member_id,
      ip: request.ip,
      accept_language: request.headers["Accept-Language"],
      ua: request.headers["User-Agent"]
    )
  end

  def save_login_history(member_id, country, user_agent)
    Loginhistory.create(
      member_id: member_id,
      ip_address: request.ip,
      login_time: DateTime.now,
      country: country,
      os: user_agent.os,
      browser: user_agent.browser
    )
  end

  def check_auth_ip(member_id, token)
    Whitelisting.create(
      member_id: member_id,
      ip_address: request.ip,
      token: token,
      expired_at: Time.zone.now + 60
    )
  end

  def set_options
    phonelib = Phonelib.parse(params[:phone_number], params[:country])
    options = {first_name: params[:first_name], last_name: params[:last_name], country: phonelib.country_code, phone_number: Phonelib.parse([phonelib.country_code, phonelib.sanitized].join).sanitized.to_s}
    options[:referral_code] = cookies[:referral_code] if cookies[:referral_code]
    options
  end

end
