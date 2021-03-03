module Matching
  class OrderBookManager

    attr :ask_orders, :bid_orders

    def self.build_order(attrs)
      attrs.symbolize_keys!

      raise ArgumentError, "Missing ord_type: #{attrs.inspect}" unless attrs[:ord_type].present?

      klass = ::Matching.const_get "#{attrs[:ord_type]}_order".camelize
      klass.new attrs
    end

    def initialize(market, options = {})
      @market = market
      @ask_orders = OrderBook.new(market, :ask, options)
      @bid_orders = OrderBook.new(market, :bid, options)
      @above_orders = StopBook.new(market, :above, options)
      @below_orders = StopBook.new(market, :below, options)
    end

    def get_books(type)
      case type
      when :ask
        [@ask_orders, @bid_orders]
      when :bid
        [@bid_orders, @ask_orders]
      end
    end

    def pop_stop_orders(price)
      stop_orders = []
      ab_ods = @above_orders.pop_stop_orders(price)
      bl_ods = @below_orders.pop_stop_orders(price)
      stop_orders += ab_ods if ab_ods
      stop_orders += bl_ods if bl_ods
      stop_orders
    end

    def get_stop_book(type)
      case type
      when :above
        @above_orders
      when :below
        @below_orders
      end
    end

  end
end
