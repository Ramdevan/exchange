module APIv2
  module Entities
    class Member < Base
      expose :sn
      expose :name
      expose :email
      expose :phone_number
      expose :activated
      expose :sms_2fa_activated
      expose :app_2fa_activated
      expose :two_factor_needed
      expose :accounts, using: ::APIv2::Entities::Account
    end
  end
end
