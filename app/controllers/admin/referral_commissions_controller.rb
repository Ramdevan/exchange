module Admin
  class ReferralCommissionsController < BaseController

    before_action :set_referral, only: [:update, :destroy]

    def index
     @commissions = ReferralCommission.all.page params[:page]
     @new_commission = ReferralCommission.new
    end

    def create
      @referal_commission = ReferralCommission.new(referral_params)
  
      respond_to do |format|
        if @referal_commission.save
          format.js 
        else
          format.js
        end
      end
    end

    def update
      respond_to do |format|
        if @referral_commission.update(referral_params)
          format.js
        else
          format.js {}
        end
      end
    end

    def destroy
      @referral_commission.destroy
      respond_to do |format|
        format.html { redirect_to admin_referral_commissions_url, notice: 'Commission was successfully Deleted.' }
      end
    end

    private

    def set_referral
      @referral_commission = ReferralCommission.find(params[:id])
    end

    def referral_params
      params.require(:referral_commission).permit(:min, :max, :fee_percent)
    end

  end
end