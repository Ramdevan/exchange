require_relative 'constants'

module Matching
  class StopBook

    attr :trigger_cond

    WEB_SOURCE = ['Web', 'APIv2']

    def initialize(market, trigger_cond, options = {})
      @market = market
      @trigger_cond = trigger_cond.to_sym # side can be
      @stop_orders = RBTree.new # RBTree for stop_limit and stop_loss orders

      @broadcast = options.has_key?(:broadcast) ? options[:broadcast] : true

      singleton =

        class << self
          self;
        end
      singleton.send :define_method, :limit_top, self.class.instance_method("#{@trigger_cond}_limit_top")
    end

    def add(order)
      raise InvalidOrderError, "volume is zero" if order.volume <= ZERO
      @stop_orders[order.stop_price] ||= PriceLevel.new(order.stop_price)
      @stop_orders[order.stop_price].add order
    end

    def pop_stop_orders(price)
      orders = []
      level = limit_top(price)
      while level
        price, level = pop
        orders += level.orders
        level = limit_top(price)
      end
      orders
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

    def remove(order)
      raise ArgumentError, "Unknow Order Type while remove stop orders #{order.class}" unless (order.is_a? StopOrder)
      price_level = @stop_orders[order.stop_price]
      return unless price_level

      order = price_level.find order.id # so we can return fresh order
      return unless order

      price_level.remove order
      @stop_orders.delete(order.stop_price) if price_level.empty?
    end

    def limit_orders
      orders = {}
      @limit_orders.keys.each do |k|
        orders[k] = (@limit_orders[k].orders rescue [])
      end
      orders
    end

    private

    def pop
      return if @stop_orders.empty?
      return @stop_orders.shift if @trigger_cond == :above
      @stop_orders.pop if @trigger_cond == :below
    end

    def above_limit_top(price)
      # lowest price wins
      return if @stop_orders.empty?
      stop_price, level = @stop_orders.first
      return if stop_price > price
      level
    end

    def below_limit_top(price)
      # highest price wins
      return if @stop_orders.empty?
      stop_price, level = @stop_orders.last
      return if stop_price < price
      level
    end

  end
end

