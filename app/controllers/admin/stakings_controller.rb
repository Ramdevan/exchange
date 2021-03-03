module Admin
  class StakingsController < BaseController
    before_action :set_staking, only: [:edit,:update_status]
    def index
      @locked_stakings = Staking.all_locked_stackings.order('published_on DESC').page(params[:page])
      @defi_stakings = Staking.all_defi_stackings.order('published_on DESC').page(params[:page])
    end

    def durations
      @durations = StakingDuration.all.order('created_at DESC').page(params[:page])
    end

    def new
      @staking = Staking.new
      @staking.staking_locked_durations.build
    end

    def new_durations
      @staking_duration = StakingDuration.new
    end

    def create
      @staking = Staking.new(staking_params)

      respond_to do |format|
        if @staking.save
          format.js 
        else
          p @staking.errors
          p "dddddddd"
          format.js
        end
      end

    end

    def update_status
      unless @staking.any_present_locked.present?
        @staking.update_attributes(is_active: !@staking.is_active)
      end
    end

    def save_durations
      @staking_duration = StakingDuration.new(staking_duration_params)
      @staking_duration.save
    end

    def get_currencies_duration
      @staking_durations = StakingDuration.where(currency: params[:currency],flexible: !(params[:staking_type] == Staking::LOCKED_STAKING))
    end


    private

    def set_staking
      @staking = Staking.find_by(id: params[:id])
    end

    def staking_duration_params
      params.require(:staking_duration).permit(
        :currency,
        :duration_days,
        :estimate_apy,
        :flexible
      )
    end

    def staking_params
      params.require(:staking).permit(\
        :staking_type,
        :currency,
        :minimum_locked_amount,
        :maximum_locked_amount,
        :published_on
      )
    end
  end
end