module Private
  class HistoryController < BaseController

    helper_method :tabs

    def account
      @market = current_market

      @deposits = Deposit.where(member: current_user).with_aasm_state(:accepted)
      @withdraws = Withdraw.where(member: current_user).with_aasm_state(:done)

      @transactions = (@deposits + @withdraws).sort_by {|t| -t.created_at.to_i }
      respond_to do |format|
        format.html { @transactions = Kaminari.paginate_array(@transactions).page(params[:page]).per(20) }
        format.xlsx { response.headers['Content-Disposition'] = "attachment; filename=account-history-#{Date.today.to_s}.xls" }
      end
    end

    def trades
      @trades = current_user.trades
        .includes(:ask_member).includes(:bid_member)
        .order('id desc').page(params[:page]).per(20)
    end

    def orders
      @orders = current_user.orders.includes(:trades).order("id desc").page(params[:page]).per(20)
    end

    def subscription
      @subscriptions = LendingSubscription.order('created_at DESC')
      @staking_subscriptions = StakingLockedSubscription.order('created_at DESC')
    end

    def redeem
      @flexibles = LendingSubscription.flexibles.not_completed.not_auto_transfer.yesterday.sort_by(&:created_at).reverse
    end

    private

    def tabs
      { order: ['header.order_history', order_history_path],
        trade: ['header.trade_history', trade_history_path],
        account: ['header.account_history', account_history_path]}
        # redeem: ['header.redeem', redeem_path] }
    end

  end
end
