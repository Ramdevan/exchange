module Verify
  class SmsAuthsController < ApplicationController
    before_action :auth_member!
    before_action :find_sms_auth
    before_action :activated?
    before_action :two_factor_required!

    def show
      @country_code = current_user.country_code_alpha
      @phone_number = Phonelib.parse(current_user.phone_number).national
    end

    def update
      if params[:commit] == 'send_code'
        send_code_phase
      else
        verify_code_phase
      end
    end

    private

    def activated?
      if @sms_auth.activated?
        redirect_to settings_path, notice: t('.notice.already_activated')
      end
    end

    def find_sms_auth
      @sms_auth ||= current_user.sms_two_factor
    end

    def send_code_phase
      @sms_auth.send_code_phase = true
      @sms_auth.assign_attributes token_params

      respond_to do |format|
        if @sms_auth.valid?
          @sms_auth.send_otp 
          service = BirdVerificationService.new(ENV['MESSAGEBIRD_WORKSPACE_ID'], ENV['MESSAGEBIRD_VERIFY_KEY'])
          identifier = {emailaddress: "#{@sms_auth.try(:member).try(:email)}" }
          steps = [{ channelId: ENV['MESSAGEBIRD_EMAIL_CHANNEL_ID'] }]
          response = service.send_verification(identifier, steps)
          if response["id"].present?
            session[:verification_id] = response["id"]
            text = I18n.t('verify.sms_auths.show.notice.send_code_success')
          else 
            text = I18n.t('verify.sms_auths.show.notice.send_code_fail')
          end
          format.any { render status: :ok, text: {text: text}.to_json }
        else
          text = @sms_auth.errors.full_messages.to_sentence
          format.any { render status: :bad_request, text: {text: text}.to_json }
        end
      end
    end

    def verify_code_phase
      @sms_auth.assign_attributes token_params
      respond_to do |format|
        service = BirdVerificationService.new(ENV['MESSAGEBIRD_WORKSPACE_ID'], ENV['MESSAGEBIRD_VERIFY_KEY'])
        response = service.verify_code(session[:verification_id], token_params[:otp])
        if @sms_auth.verify? || response["id"].present?
          @sms_auth.active! and unlock_two_factor!
          text = I18n.t('verify.sms_auths.show.notice.otp_success')
          flash[:notice] = text
          format.any { render status: :ok, text: {text: text, reload: true}.to_json }
        else
          text = @sms_auth.errors.full_messages.to_sentence
          format.any { render status: :bad_request, text: {text: text}.to_json }
        end
      end
    end

    def token_params
      params.required(:sms_auth).permit(:country, :phone_number, :otp)
    end

    def two_factor_required!
      return if not current_user.app_two_factor.activated?

      if two_factor_locked?
        session[:return_to] = request.original_url
        redirect_to two_factors_path
      end
    end

  end
end
