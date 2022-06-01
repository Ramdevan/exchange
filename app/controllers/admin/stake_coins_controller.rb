module Admin
  class StakeCoinsController < BaseController
    def index
      @stake_coins = StakeCoin.all.includes(:variable_apy)
    end

    def new
      @currency = Currency.all
      @stake_coin = StakeCoin.new
    end
    def edit
      @currency = Currency.all
      @stake_coin = StakeCoin.where(id: params[:id]).includes(:variable_apy).first
      if(@stake_coin.member_stake_coin.any?)
        flash[:alert] = "Cannot edit Staking since users have already invested."
        @stake_coins = StakeCoin.all.includes(:variable_apy)
        redirect_to admin_stake_coins_path and return
      end
    end
    def create
      @stake_coin = StakeCoin.new(stake_coin_params)
      unless @stake_coin.valid?
        errors = []
        @stake_coin.errors.messages.each do |key, value|
            errors << value 
        end

        flash[:alert] = errors.join(", ")
        @currency = Currency.all
        render "new" and return
      end
      @stake_coin.save
      redirect_to admin_stake_coin_path(@stake_coin)
    end

    def update
      @stake_coin = StakeCoin.where(id: params[:id]).includes(:variable_apy).first
      if(@stake_coin.member_stake_coin.any?)
        flash[:alert] = "Cannot edit Staking since users have already invested."
        @stake_coins = StakeCoin.all.includes(:variable_apy)
        redirect_to admin_stake_coins_path and return
      end
      unless @stake_coin.update(stake_coin_params)
        errors = []
        @stake_coin.errors.messages.each do |key, value|
            errors << value 
        end

        flash[:alert] = errors.join(", ")
        @currency = Currency.all
        render "edit" and return
      end
      redirect_to admin_stake_coin_path(@stake_coin)
    end

    def show
      @stake_coin = StakeCoin.where(id: params[:id]).includes(:variable_apy).first
      unless @stake_coin
        @stake_coins = StakeCoin.all.includes(:variable_apy)
        flash[:alert] = "Stakecoin plan not found."
        redirect_to admin_stake_coins_path
      end
    end

    def update_status
      @stake_coin = StakeCoin.where(id: params[:id]).first
      @stake_coin.update(is_active: params[:is_active])
      if(@stake_coin.is_active)
        flash[:notice] = "Staking Plan has been successfully activated."
      else
        flash[:notice] = "Staking Plan has been successfully deactivated."
      end
      @stake_coins = StakeCoin.all.includes(:variable_apy)
      redirect_to admin_stake_coins_path
    end

    private

    def stake_coin_params
      params.require(:stake_coin).permit(:currency, :min_deposit, :max_deposit, :max_lot_size, :duration, :is_flexible, variable_apy_attributes: [:id, :lot_size, :apy, :_destroy])
    end
  end
end
