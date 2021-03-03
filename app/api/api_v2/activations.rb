module APIv2
  class Activations < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }
    
    desc "Send verification mail"
    post "/verify/mail" do
      current_user.send_activation

      status 200
      text = I18n.t('verify.sms_auths.show.notice.send_email_success')
      return :success => { :message => text }
    end

    desc "Update mobile number and send verification code."
    params do
      requires :country, type: String, desc: 'Provide your current Country.'
      requires :phone_number, type: String, desc: 'Provide a valid phone number'
    end
    put "/send/otp" do
      sms_auth ||= current_user.sms_two_factor
      if sms_auth.activated?
        raise CustomError, @params[:message] = I18n.t('verify.sms_auths.show.notice.already_activated')
      end

      sms_auth.send_code_phase = true
      sms_auth.assign_attributes params.as_json(only: %i[country phone_number])

      if sms_auth.valid?
        sms_auth.send_otp
        text = I18n.t('verify.sms_auths.show.notice.send_code_success')

        status 200
        return :success => { :message => text }
      else
        raise CustomError, @params[:message] = sms_auth.errors.full_messages.to_sentence
      end
    end

    desc "Verify mobile number using provided OTP."
    params do
      requires :country, type: String, desc: 'Provide your current Country.'
      requires :phone_number, type: String, desc: 'Provide a valid phone number'
      requires :otp, type: String, desc: 'Provide the one time password.'
    end
    put "/verify/phone" do
      sms_auth ||= current_user.sms_two_factor
      if sms_auth.activated?
        raise CustomError.new(I18n.t('verify.sms_auths.show.notice.already_activated'))
      end

      sms_auth.assign_attributes params.as_json(only: %i[country phone_number otp])

      if sms_auth.verify?
        sms_auth.active!
        
        text = I18n.t('verify.sms_auths.show.notice.otp_success')
        status 200
        return :success => { :message => text }
      else
        raise CustomError, @params[:message] = sms_auth.errors.full_messages.to_sentence
      end
    end

    desc "Send OTP to registered mobile number."
    get "/two_factor/sms" do
      two_factor = current_user.sms_two_factor
      if two_factor
        two_factor.refresh!
        two_factor.send_otp
        return :success => { message: "OTP sent successfully." }
      else
        raise CustomError.new("Failed to send OTP.")
      end
    end

    desc "Verify the two factor sms authentication. Provide the one time password."
    params do
      requires :two_factor_type, type: String, desc: 'Provide the two factor type (sms, app).'
      requires :two_factor_otp, type: String, desc: 'Provide the one time password.'
    end
    put "/two_factor/sms" do
      if two_factor_auth_verified?
        return :success => { message: I18n.t('verify.sms_auths.show.notice.otp_success') }
      else
        raise CustomError.new(I18n.t('two_factors.update.alert'))
      end
    end

    desc "Get google authenticator key."
    get "/two_factor/app" do
      google_auth ||= current_user.app_two_factor

      if not current_user.sms_two_factor.activated?
        raise CustomError.new(I18n.t('two_factors.auth.please_active_two_factor'))
      elsif google_auth.activated?
        status 302
        return :success => { message: I18n.t('verify.google_auths.show.notice.already_activated') }
      else
        google_auth.refresh!
      end

      google_auth.as_json(only: %[otp_secret])
    end

    desc "Verify two factor google authentication."
    params do
      requires :gauth_otp, type: String, desc: 'Provide the one time password.'
    end
    put "/two_factor/app" do
      @google_auth ||= current_user.app_two_factor
      if one_time_password_verified?
        @google_auth.active!
        status 200
        return :success => { message: I18n.t('verify.google_auths.update.notice') }
      else
        raise CustomError.new(I18n.t('verify.google_auths.update.alert'))
      end
    end

    desc "Destroy two factor google authentication."
    params do
      requires :gauth_otp, type: String, desc: 'Provide the one time password.'
    end
    delete "/two_factor/app" do
      @google_auth ||= current_user.app_two_factor
      if one_time_password_verified?
        @google_auth.deactive!
        status 200
        return :success => { message: I18n.t('verify.google_auths.destroy.notice') }
      else
        raise CustomError.new(I18n.t('verify.google_auths.destroy.alert'))
      end
    end

    get "/document/edit" do
      document = current_user.id_document || current_user.create_id_document

      status 200
      document.attributes.merge(bill_file: document.bill_file_path, document_file: document.document_file_path)
    end

    params do
      use :documents
    end
    put "/document/update" do
      document = current_user.id_document if current_user
      # Checking document verification status
      if document.aasm_state == I18n.t('private.id_documents.edit.state_verifying')
        raise CustomError, @params[:message] = I18n.t('private.id_documents.update.notice.verification_submitted')
      elsif document.aasm_state == I18n.t('private.id_documents.edit.state_verified')
        raise CustomError, @params[:message] = I18n.t('private.id_documents.update.notice.verification_completed')
      elsif document.aasm_state == I18n.t('private.id_documents.edit.state_unverified')
        # Processing documents when document verification is not done
        begin
          attachments = Asset.where(:attachable_id => document.id)

          # Submit documents for verification
          document = create_or_update_documents(document, attachments, params.document_file, params.bill_file)

          if document.update_attributes(params.as_json(:only => %i[name birth_date address city country zipcode id_document_type id_document_number id_bill_type]))
            document.submit!

            status 200
            document.attributes.merge(bill_file: document.bill_file_path, document_file: document.document_file_path)
          end
        rescue => e
          ExceptionNotifier.notify_exception(e, env: request.env)
          raise PathNotFoundError
        end
      end
    end

    get "/activation/status" do
      mail_verification = false
      document_verification = I18n.t('private.id_documents.edit.state_unverified')
      two_factor_verification = false

      # Checking mail, document, 2fa verification status
      mail_verification = true if current_user.activated?
      document_verification = current_user.id_document.aasm_state if current_user
      two_factor_verification = true if current_user.sms_two_factor.activated?

      status 200
      return :mail_verification => mail_verification, :document_verification => document_verification, :two_factor_verification => two_factor_verification
    end

    get "/verification/data" do
      data = {
        countries: ISO3166::Country.all.sort.map {|country| {country_code: country[1], country_name: country[0]}},
        documents: IdDocument.id_document_type.values.map {|doc| {document_code: doc, document_name: doc.gsub("_", " ").titleize} },
        residence: IdDocument.id_bill_type.values.map {|bill| {document_code: bill, document_name: bill.gsub("_", " ").titleize} }
      }

      status 200
      data
    end

  end
end