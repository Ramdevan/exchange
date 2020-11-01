module APIv2
  class Members < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get your profile and accounts info.', scopes: %w(profile)
    params do
      use :auth
    end
    get "/members/me" do
      authenticate!
      member = current_user
      if member.country_code.present?
        phone = member.phone_number.sub(member.country_code.to_s, "")
        member.phone_number = phone
      end
      member.sms_2fa_activated = current_user.sms_two_factor.activated?
      member.app_2fa_activated = current_user.app_two_factor.activated?
      member.two_factor_needed = false
      present member, with: APIv2::Entities::Member
    end

    desc 'Use your credentials to login.'
    params do
      # Checking presence of Email and Password
      requires :email, type: String, desc: "Email associated with your account."
      requires :password, type: String, desc: "Valid password for your account"
    end
    post "/login" do
      begin
        token = login_member(params[:email], params[:password])
        member = current_user

        response = token.as_json(only: %i[access_key secret_key])
        response[:sms_2fa_activated] = member.sms_two_factor.activated?
        response[:app_2fa_activated] = member.app_two_factor.activated?
        status 200
        return response
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        raise CustomError.new("Incorrect Email or Password")
      end
    end

    desc 'Register user'
    params do
      # Checking presence of Email and Password
      requires :email, type: String, desc: "Email associated with your account."
      requires :password, type: String, desc: "Valid password for your account"
      requires :password_confirmation, type: String, desc: "Confirm password for your account"
    end
    post "/register" do
      raise CustomError, @params[:message] = "Password doesn't match" unless params[:password] == params[:password_confirmation]

      identity = Identity.find_by(email: params[:email])
      if identity
        raise CustomError, @params[:message] = "Email already exists"
      else
        # begin
        identity = Identity.create(email: params[:email], phone_number: params[:phone_number], country: params[:country_code],
                                   first_name: params[:first_name], last_name: params[:last_name])
        identity.password = identity.password_confirmation = params[:password]
        if identity.valid?
          identity.save!

          member = Member.find_by(email: params[:email])
          unless member
            member = Member.find_or_create_by(email: params[:email])
            phonelib = Phonelib.parse(params[:phone_number], params[:country_code])
            member.phone_number = Phonelib.parse([phonelib.country_code, phonelib.sanitized].join).sanitized.to_s
            member.country_code = phonelib.country_code
            member.authentications.build(provider: 'identity', uid: identity.id)
          end

          if member.valid?
            member.save!
            SignupHistory.create(member_id: member.id, ip: request.ip, accept_language: request.headers["Accept-Language"], ua: request.headers["User-Agent"])
            id_document = member.id_document || member.create_id_document
            if id_document
              id_document.first_name = params[:first_name]
              id_document.last_name = params[:last_name]
              id_document.save(validate: false)
            end
            token = login_member(params[:email], params[:password])
            status 200
            return token.as_json(only: %i[access_key secret_key])
          else
            raise CustomError, @params[:message] = member.errors.full_messages.first
          end
        else
          raise CustomError, @params[:message] = identity.errors.full_messages.first
        end
        # rescue => e
        #   ExceptionNotifier.notify_exception(e, env: request.env)
        #   raise PathNotFoundError
        # end
      end
    end

    desc 'Logout from the account.', scopes: %w(profile)
    params do
      use :auth
    end
    delete "/logout" do
      begin
        authenticate!
        access_key = params[:access_key]
        token = APIToken.where(:member_id => current_user.id, :access_key => access_key)
        token.first.delete unless token.empty?
        
        @current_user ||= Member.current = nil

        status 200
        return :success => { :message => "Logged out successfully" }
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        raise PathNotFoundError
      end
    end

    get "/check/otp" do
      return :otp => current_user.sms_two_factor.otp_secret
    end

    desc 'Reset password'
    params do
      # Checking presence of Email
      requires :email, type: String, desc: "Email associated with your account."
    end
    post "/reset/password" do
      token = Token::ResetPassword.new(params.as_json(only: %i[email]))

      if token.save
        clear_all_sessions token.member_id
        status 200
        return :success => { :message => "Password reset mail sent, please check your mailbox." }
      else
        msg = token.errors.full_messages.join(', ')
        raise CustomError.new(msg)
      end
    end

    desc 'Change password'
    params do
      use :auth
      # Checking presence of Email and Password
      requires :old_password, type: String, desc: "Enter your old password"
      requires :password, type: String, desc: "New password for your account"
      requires :password_confirmation, type: String, desc: "Confirm your new password"
    end
    put "/change/password" do
      authenticate!
      identity = current_user.identity

      unless identity.authenticate(params[:old_password])
        raise CustomError.new(I18n.t('identities.update.auth-error'))
      end

      if identity.authenticate(params[:password])
        raise CustomError.new(I18n.t('identities.update.auth-same'))
      end

      if identity.update_attributes(params.as_json(only: %i[old_password password password_confirmation]))
        current_user.send_password_changed_notification
        clear_all_sessions current_user.id

        status 200
        return :success => { :message => "Password changed successfully." }
      else
        msg = "Failed to change password."
        raise CustomError.new(msg)
      end
    end

  end
end
