module Private
  class ReferralsController < BaseController
    def index
      @referred_members = current_user.referred_users.page(params[:page]).per(20)
    end
  end
end