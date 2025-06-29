module APIv2
  class Orders < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }

    desc 'Get your orders, results is paginated.', scopes: %w(history trade)
    params do
      use :auth
      optional :state, type: String,  default: 'wait', values: Order.state.values, desc: "Filter order by state, default to 'wait' (active orders)."
      optional :order_by, type: String, values: %w(asc desc), default: 'desc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
    end
    get "/history/orders/my" do
      orders = current_user.orders
                   .order(order_param)

      present :history, orders, with: APIv2::Entities::Order
    end

    desc 'Get your market orders, results is paginated.', scopes: %w(history trade)
    params do
      use :auth, :market
      optional :state, type: String,  default: 'wait', values: Order.state.values, desc: "Filter order by state, default to 'wait' (active orders)."
      optional :order_by, type: String, values: %w(asc desc), default: 'asc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
    end
    get "/orders/:market" do
      orders = current_user.orders
                   .order(order_param)
                   .with_currency(current_market)
                   .with_state(params[:state])

      present orders, with: APIv2::Entities::Order
    end

    desc 'Get your orders, results is paginated.', scopes: %w(history trade)
    params do
      use :auth
      optional :state, type: String,  default: 'wait', values: Order.state.values, desc: "Filter order by state, default to 'wait' (active orders)."
      optional :order_by, type: String, values: %w(asc desc), default: 'asc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
    end
    get "/orders" do
      orders = current_user.orders
                   .order(order_param)
                   .with_state(params[:state])

      present :orders, orders, with: APIv2::Entities::Order
    end

    desc 'Get information of specified order.', scopes: %w(history trade)
    params do
      use :auth, :order_id
    end
    get "/order" do
      order = current_user.orders.where(id: params[:id]).first
      raise OrderNotFoundError, params[:id] unless order
      present order, with: APIv2::Entities::Order, type: :full
    end

    desc 'Create multiple sell/buy orders.', scopes: %w(trade)
    params do
      use :auth, :market
      requires :orders, type: Array do
        use :order
      end
    end
    post "/orders/multi" do
        orders = create_orders params[:orders]
        present orders, with: APIv2::Entities::Order
    end

    desc 'Create a Sell/Buy order.', scopes: %w(trade)
    params do
      use :auth, :market, :order
    end
    post "/orders" do
      order = create_order params
      status 200
      present order, with: APIv2::Entities::Order
    end

    desc 'Cancel an order.', scopes: %w(trade)
    params do
      use :auth, :order_id
    end
    post "/order/delete" do
      begin
        order = current_user.orders.find(params[:id])
        Ordering.new(order).cancel
        present order, with: APIv2::Entities::Order
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        raise CancelOrderError, $!
      end
    end

    desc 'Cancel all my orders.', scopes: %w(trade)
    params do
      use :auth
      optional :side, type: String, values: %w(sell buy), desc: "If present, only sell orders (asks) or buy orders (bids) will be canncelled."
    end
    post "/orders/clear" do
      begin
        orders = current_user.orders.with_state(:wait)
        if params[:side].present?
          type = params[:side] == 'sell' ? 'OrderAsk' : 'OrderBid'
          orders = orders.where(type: type)
        end
        orders.each {|o| Ordering.new(o).cancel }
        present orders, with: APIv2::Entities::Order
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        raise CancelOrderError, $!
      end
    end

  end
end
