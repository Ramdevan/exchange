module Private
  class SettingsController < BaseController

    skip_before_action :auth_member!, only: [:fee]    # :two_factor_required!,

    def index
      unless current_user.activated?
        flash.now[:info] = t('.activated')
      end
    end

    def fee
      @fee = Currency.all_fee_details
    end

  end
end

