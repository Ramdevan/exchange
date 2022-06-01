module Private
    class MemberStakeCoinCreditHistoriesController < BaseController
        def index
            member_stake_coin = MemberStakeCoin.where(member_id: current_user.id, id: params[:member_stake_coin_id]).first
            @member_stake_coin_credit_history = MemberStakeCoinCreditHistory.where(member_stake_coin_id: member_stake_coin.id).order(id: :desc).page(params[:page]).per(10) if member_stake_coin || []
        end
    end

  end
  