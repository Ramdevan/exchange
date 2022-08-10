module Admin
  class FeesController < BaseController

    before_action :set_fee, only: [:update, :destroy]

    def index
     @fees = Fee.all.page params[:page]
     @new_fee = Fee.new
    end

    def create
      @fee = Fee.new(fee_params)
  
      respond_to do |format|
        if @fee.save
          format.js 
        else
          format.js
        end
      end
    end

    def update
      respond_to do |format|
        if @fee.update(fee_params)
          format.js
        else
          format.js {}
        end
      end
    end

    def destroy
      @fee.destroy
      respond_to do |format|
        format.html { redirect_to admin_fees_url, notice: 'Fee was successfully deleted.' }
      end
    end

    private

    def set_fee
      @fee = Fee.find(params[:id])
    end

    def fee_params
      params.require(:fee).permit(:min, :max, :taker, :maker)
    end

  end
end