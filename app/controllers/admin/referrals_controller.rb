module Admin
  class ReferralsController < BaseController
    def index
      @members = Member.all.page params[:page]
    end
  end
end
