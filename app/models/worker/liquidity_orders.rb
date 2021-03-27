module Worker
  class LiquidityOrders

    ORDER_EXIST_STATES = ['NEW', 'PARTIALLY_FILLED', 'FILLED', 'PENDING_CANCEL']

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!
      case payload[:source]
        when 'Binance'
          process_binance_order(payload)
        else
      end
    end

    def process_binance_order(payload)
      id = payload[:order_id]
      case payload[:action]
        when "create"
          create_binance_order id
        when "update"
          update_binance_order(id, payload[:volume])
        when "cancel"
          cancel_binance_order id
        else
      end
    end

    def create_binance_order id
      return unless ENV['PLACE_LIQUIDITY_ORDERS'] == 'true'
      return unless ENV['LIQUIDITY_ENABLED'] == 'true'
      order = Order.find(id)
      binance_client = BinanceRestClient.new order.config
      liquidity_status = LiquidityStatus.find_by_order_id(id)
      
      if liquidity_status && ORDER_EXIST_STATES.include?(liquidity_status.state)
        Rails.logger.info "===== Order already present in binance, Skipping it ====="
      else
        result = binance_client.place_binance_order({ quantity: order.volume, price: order.price, side: order.type })
        case result['status']
          when "FILLED"
            binance_client.fill_orders order, {price: result['price'], quantity: result['executedQty'], side: result['side']}
          when "PARTIALLY_FILLED"
            binance_client.fill_orders order, {price: result['price'], quantity: result['executedQty'], side: result['side']}
          else
        end
        liquidity_status = order.liquidity_status || order.create_liquidity_status(liquid_id: result['orderId'], state: result['status'])
        liquidity_status.liquidity_histories.create(detail: result)
      end
    end

    def update_binance_order(id, updated_volume)
      return unless ENV['PLACE_LIQUIDITY_ORDERS'] == 'true'
      return unless ENV['LIQUIDITY_ENABLED'] == 'true'
      order = Order.find(id)
      binance_client = BinanceRestClient.new order.config
      liquidity_status = LiquidityStatus.find_by_order_id(order.id)

      if liquidity_status
        # Create binance order with new quantity
        result = binance_client.place_binance_order({ quantity: updated_volume, price: order.price, side: order.type })
        liquidity_status.update(liquid_id: result['orderId'], state: result['status'])
        data = {
          msg: "Partial trade executed, so updated Liquidity quantity & state",
          origQty: order.origin_volume, # Quantity with which the order gets created
          currentQty: updated_volume # Quantity after partial trade
        }
        liquidity_status.liquidity_histories.create(detail: data)
        liquidity_status.liquidity_histories.create(detail: result)
      else
        Rails.logger.info "===== Order not present in binance, Skipping it ====="
      end
    end

    def cancel_binance_order id
      return unless ENV['LIQUIDITY_ENABLED'] == 'true'
      order = Order.find(id)
      binance_client = BinanceRestClient.new order.config
      liquidity_status = order.liquidity_status
      return unless liquidity_status.present?
      result = binance_client.cancel_binance_order(liquidity_status.liquid_id)
      liquidity_status.update_attributes(state: result['status'])
      liquidity_status.liquidity_histories.create(detail: result)
    end
  end
end
