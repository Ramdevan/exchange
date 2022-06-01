module Private
    class MemberStakeCoinsController < BaseController
        def index
            @member_stake_coins = MemberStakeCoin.where(member_id: current_user.id, stake_coin_id: params[:stake_coin_id]).includes(:stake_coin,stake_coin: :current_variable_apy)
        end
      def create
        @member_stake_coin = MemberStakeCoin.new(member_stake_coin_params)
        @member_stake_coin.member_id = current_user.id
        @member_stake_coin.start_date = Time.zone.now
        stake_coin = StakeCoin.find(@member_stake_coin.stake_coin_id)
        exisiting_member_stake_coins = MemberStakeCoin.where(member_id: current_user.id, stake_coin_id: stake_coin.id, aasm_state: :accepted)
        current_staked_amount = 0.0
        exisiting_member_stake_coins.each do |exisiting_member_stake_coin|
          current_staked_amount += exisiting_member_stake_coin.amount
        end
        if(current_staked_amount + @member_stake_coin.amount > stake_coin.max_deposit)
          flash[:alert] = "Max limit is #{stake_coin.max_deposit}"
          redirect_to stake_coins_path and return
        end
        if(stake_coin.min_deposit > @member_stake_coin.amount || stake_coin.max_deposit < @member_stake_coin.amount)
            flash[:alert] = "Investment amount should be in the range #{stake_coin.min_deposit} and #{stake_coin.max_deposit}"
            redirect_to stake_coins_path and return
        end
        unless(stake_coin.is_flexible)
            @member_stake_coin.end_date = (Time.zone.now + stake_coin.duration.days).end_of_day
        end
        if stake_coin.max_lot_size < (stake_coin.cur_lot_size + @member_stake_coin.amount)
            flash[:alert] = "Maximum investement amount for the plan is reached."
            redirect_to stake_coins_path and return
        end
        # @member_stake_coin.calculate_interest_per_day(stake_coin)
        account = Account.where(member_id: current_user.id, currency: stake_coin.currency).first
        if account.balance < @member_stake_coin.amount
            flash[:alert] = "Balance not enough"
            redirect_to stake_coins_path and return
        end
        if @member_stake_coin.save
            @member_stake_coin.submit!
            redirect_to member_stake_coins_path(stake_coin_id: stake_coin.id) and return
        end
        flash[:alert] = "Save Failed"
        redirect_to stake_coins_path
      end
      def update
        @member_stake_coin = MemberStakeCoin.find params[:id]
        unless @member_stake_coin.stake_coin.is_flexible
            flash[:alert] = "Cannot modify locked staking."
            redirect_to member_stake_coins_path and return
        end
        @member_stake_coin.end_date = Time.zone.now
        @member_stake_coin.mature
        @member_stake_coin.save
        flash[:notice] = "Redeemed successfully."
        redirect_to member_stake_coins_path(stake_coin_id: @member_stake_coin.id)
      end



      def member_stake_coin_params
        params.require(:member_stake_coin).permit(:stake_coin_id, :amount)
      end
    end


  end
  