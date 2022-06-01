module Private
    class StakeCoinsController < BaseController
      def index
        @stake_coins = StakeCoin.all.includes(:current_variable_apy)
      end
    end
  end
  