module Admin
  class TwoFactorsController < BaseController
    load_and_authorize_resource

    def destroy
      @two_factor.deactive!
      flash[:notice] = "Deactivated Successfully"
      redirect_to :back
    end
  end
end
