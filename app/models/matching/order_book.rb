require_relative 'constants'

module Matching
  class OrderBook

    attr :side

    BINANCE_SOURCE = "Binance"
    WEB_SOURCE = ['Web', 'APIv2']

    def initialize(market, side, options = {})
      @market = market
      @side = side.to_sym
      @web_limit_orders = RBTree.new
      @limit_orders = RBTree.new
      @market_orders = RBTree.new
      @stop_loss_orders = RBTree.new

      @broadcast = options.has_key?(:broadcast) ? options[:broadcast] : true
      broadcast(action: 'new', market: @market, side: @side)

      singleton =

        class << self
          self;
        end
      singleton.send :define_method, :limit_top, self.class.instance_method("#{@side}_limit_top")
    end

    def best_limit_price
      limit_top.try(:price)
    end

    def top(is_stop = false)
      @is_stop = is_stop
      @market_orders.empty? ? limit_top : @market_orders.first[1]
    end

    def fill_top(trade_price, trade_volume, trade_funds)
      order = top
      raise "No top order in empty book." unless order

      order.fill trade_price, trade_volume, trade_funds
      AMQPQueue.enqueue(:liquidity_orders, action: 'cancel', source: BINANCE_SOURCE, order_id: order.id) if (Order.check_eligibility(order.id, BINANCE_SOURCE))
      if order.filled?
        remove order
      else
        broadcast(action: 'update', order: order.attributes)
        AMQPQueue.enqueue(:liquidity_orders, action: 'update', source: BINANCE_SOURCE, order_id: order.id) if (Order.check_eligibility(order.id, BINANCE_SOURCE))
      end
    end

    def find(order)
      case order
      when LimitOrder
        match_order = @limit_orders[order.price]
        match_order.present? ? match_order.find(order.id) : nil
      when MarketOrder
        @market_orders[order.id]
      end
    end

    def add(order)
      raise InvalidOrderError, "volume is zero" if order.volume <= ZERO

      case order
      when LimitOrder
        @limit_orders[order.price] ||= PriceLevel.new(order.price)
        @limit_orders[order.price].add order
        if WEB_SOURCE.include?(order.source)
          @web_limit_orders[order.price] ||= PriceLevel.new(order.price)
          @web_limit_orders[order.price].add order
        end
      when MarketOrder
        @market_orders[order.id] = order
      when StopLossOrder
        @stop_loss_orders[order.price] ||= PriceLevel.new(order.price)
        @stop_loss_orders[order.price].add order
      else
        raise ArgumentError, "Unknown order type"
      end

      broadcast(action: 'add', order: order.attributes)
    end

    def remove(order)
      case order
      when LimitOrder
        remove_web_limit_order(order)
        remove_limit_order(order)
      when MarketOrder
        remove_market_order(order)
      when StopLossOrder
        remove_stop_loss_order(order)
      else
        raise ArgumentError, "Unknown order type"
      end
    end

    def limit_orders
      orders = {}
      @limit_orders.keys.each do |k|
        orders[k] = (@limit_orders[k].orders rescue [])
      end
      # @limit_orders.keys.each {|k| orders[k] = @limit_orders[k].orders }
      orders
    end

    def market_orders
      @market_orders.values
    end

    def stop_loss_orders
      @stop_loss_orders.values
    end

    def liquidity_orderbook_limit_top
      return if @limit_orders.empty?
      case side
      when :ask
        price, level = @limit_orders.first
        return level.top
      when :bid
        price, level = @limit_orders.last
        return level.top
      else
      end
    end

    def broadcast(data)
      return unless @broadcast
      # Rails.logger.debug "orderbook broadcast: #{data.inspect}"
      AMQPQueue.enqueue(:slave_book, data, { persistent: false })
    end

    private

    def remove_web_limit_order(order)
      price_level = @web_limit_orders[order.price]
      return unless price_level

      order = price_level.find order.id # so we can return fresh order
      return unless order

      price_level.remove order
      @web_limit_orders.delete(order.price) if price_level.empty?
    end

    def remove_limit_order(order)
      price_level = @limit_orders[order.price]
      return unless price_level

      order = price_level.find order.id # so we can return fresh order
      return unless order

      price_level.remove order
      @limit_orders.delete(order.price) if price_level.empty?

      broadcast(action: 'remove', order: order.attributes)
      order
    end

    def remove_market_order(order)
      if order = @market_orders[order.id]
        @market_orders.delete order.id
        broadcast(action: 'remove', order: order.attributes)
        order
      end
    end

    def remove_stop_loss_order(order)
      price_level = @stop_loss_orders[order.price]
      return unless price_level

      order = price_level.find order.id # so we can return fresh order
      return unless order

      price_level.remove order
      @stop_loss_orders.delete(order.price) if price_level.empty?
    end

    def ask_limit_top # lowest price wins
      if @is_stop
        return if @web_limit_orders.empty?
        price, level = @web_limit_orders.first
        return level.top
      end
      wprice, wlevel =  @web_limit_orders.first unless @web_limit_orders.empty?
      sprice, slevel = @stop_loss_orders.first unless @stop_loss_orders.empty?

      if wprice and sprice
        level = sprice <= wprice ? slevel : wlevel
      elsif wprice
        level = wlevel
      elsif sprice
        level = slevel
      else
        return
      end
      level.top

    end

    def bid_limit_top # highest price wins
      if @is_stop
        return if @web_limit_orders.empty?
        price, level = @web_limit_orders.last
        return level.top
      end
      wprice, wlevel =  @web_limit_orders.last unless @web_limit_orders.empty?
      sprice, slevel = @stop_loss_orders.last unless @stop_loss_orders.empty?

      if wprice and sprice
        level = sprice >= wprice ? slevel : wlevel
      elsif wprice
        level = wlevel
      elsif sprice
        level = slevel
      else
        return
      end
      level.top


    end

  end
end
