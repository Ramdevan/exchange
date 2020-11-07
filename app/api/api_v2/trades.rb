module APIv2
  class Trades < Grape::API
    helpers ::APIv2::NamedParams

    desc 'Get recent trades on market, each trade is included only once. Trades are sorted in reverse creation order.'
    params do
      use :trade_filters
    end
    get "/history/trades/:market/all" do
      trades = Trade.filter(params[:market], time_to, params[:from], params[:to], params[:limit], order_param)
      present trades, with: APIv2::Entities::Trade
    end

    desc 'Get your executed trades. Trades are sorted in reverse creation order.', scopes: %w(history)
    params do
      use :auth, :market, :trade_filters
    end
    get "/history/trades/:market/my" do
      authenticate!

      trades = Trade.for_member(
        params[:market], current_user,
        limit: params[:limit], time_to: time_to,
        from: params[:from], to: params[:to],
        order: order_param
      )

      present trades, with: APIv2::Entities::Trade, current_user: current_user
    end

    desc 'Get your executed trades. Trades are sorted in reverse creation order.', scopes: %w(history)
    params do
      use :auth
      optional :order_by, type: String, values: %w(asc desc), default: 'desc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
    end
    get "/history/trades/my" do
      authenticate!

      member = current_user
      trades = member.trades
                   .order(order_param)

      trades.each do |trade|
        trade.side = trade.ask_member_id == member.id ? 'ask' : 'bid'
        # market = Market.find_by_id(trade.currency)
        trade.base_currency = trade.market.base_unit
        trade.quote_currency = trade.market.quote_unit
      end

      present :history, trades, with: APIv2::Entities::Trade, current_user: current_user
    end

    desc 'Get your account history.', scopes: %w(history)
    params do
      use :auth
    end
    get "/history/account/my" do
      authenticate!

      deposits = current_user.deposits.with_aasm_state(:accepted)
      withdraws = current_user.withdraws.with_aasm_state(:done)

      transactions = (deposits + withdraws).sort_by {|t| -t.created_at.to_i }
      present :history, transactions, with: APIv2::Entities::Transaction
    end

  end
end
