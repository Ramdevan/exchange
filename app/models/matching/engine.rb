module Matching
  class Engine

    attr :orderbook, :mode, :queue
    delegate :ask_orders, :bid_orders, to: :orderbook

    BINANCE_SOURCE = 'Binance'
    WEB_SOURCE = ['Web', 'APIv2']

    def initialize(market, options = {})
      @market = market
      @orderbook = OrderBookManager.new(market.id)

      # Engine is able to run in different mode:
      # dryrun: do the match, do not publish the trades
      # run:    do the match, publish the trades (default)
      shift_gears(options[:mode] || :run)
    end

    def submit(order)
      book, counter_book = orderbook.get_books order.type
      ok = true
      if order.source == BINANCE_SOURCE
        ok = strike_binance_order(order, book, counter_book)
      else
        match order, counter_book unless order.is_a? StopOrder
      end
      add_or_cancel order, book if ok
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.fatal "Failed to submit order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def cancel(order)
      book, counter_book = orderbook.get_books order.type
      if order.is_a? StopLimitOrder
        Rails.logger.info "Cancel order: #{order}"
        book = orderbook.get_stop_book order.trigger_cond
      end
      if removed_order = book.remove(order)
        publish_cancel removed_order, "cancelled by user"
      elsif !is_binance_orderbook(order)
        if Order.where(id: order.id, state: :wait).count == 1
          publish_cancel order, "cancelled by user"
        else
          Rails.logger.warn "Cannot find order##{order.id} in order-book to cancel, skip."
        end
      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.fatal "Failed to cancel order #{order.label}: #{$!}"
      Rails.logger.fatal $!.backtrace.join("\n")
    end

    def limit_orders
      { ask: ask_orders.limit_orders,
        bid: bid_orders.limit_orders }
    end

    def market_orders
      { ask: ask_orders.market_orders,
        bid: bid_orders.market_orders }
    end

    def shift_gears(mode)
      case mode
      when :dryrun
        @queue = []

        class << @queue
          def enqueue(*args)
            push args
          end
        end
      when :run
        @queue = AMQPQueue
      else
        raise "Unrecognized mode: #{mode}"
      end

      @mode = mode
    end

    private

    def match(order, counter_book)
      return if order.filled?

      counter_order = counter_book.top(order.is_a? StopOrder)
      return unless counter_order
      return if [counter_order.source, order.source].include? BINANCE_SOURCE

      # For web orders
      if trade = order.trade_with(counter_order, counter_book)
        # check stop orders
        stop_orders = orderbook.pop_stop_orders trade[0]
        stop_orders.each do |s_order|
          AMQPQueue.enqueue(:matching, action: 'submit', order: s_order.attributes)
          s_order
        end

        # end check stop orders

        counter_book.fill_top *trade
        order.fill *trade

        publish order, counter_order, trade

        if counter_order.is_a? StopLossOrder
          counter_book.remove counter_order
          counter_order.started = true
          AMQPQueue.enqueue(:matching, action: 'resubmit', order: counter_order.attributes)
        end

        match order, counter_book
        # end
      end
    end

    def strike_binance_order(order, book, counter_book)
      counter_order = counter_book.liquidity_orderbook_limit_top
      return true unless counter_order
      if counter_order.source == BINANCE_SOURCE
        if trade = order.trade_with(counter_order, counter_book)
          order.fill *trade
          counter_order.fill *trade
          if order.filled?
            book.remove order
            counter_book.broadcast(action: 'update', order: counter_order.attributes)
            return false
          elsif counter_order.filled?
            counter_book.remove counter_order
            strike_binance_order(order, book, counter_book)
          end
        end
      elsif !LiquidityStatus.find_by_order_id(counter_order.id) && WEB_SOURCE.include?(counter_order.source)
        return strike_cross_order(order, book, counter_order, counter_book)
      end
      return true
    end

    def strike_cross_order(order, book, counter_order, counter_book)
      if trade = order.trade_with(counter_order, counter_book)
        # Fill Web order
        order.fill *trade
        counter_order.fill *trade
        web_order = Order.find(counter_order.id)
        trade_data = { price: trade[0], quantity: trade[1], side: (counter_order.type == :bid ? "BUY" : "ASK") }
        BinanceRestClient.new(Market.find(web_order.market)).fill_orders(web_order, trade_data, true)

        if counter_order.filled?
          counter_book.remove counter_order
          return strike_binance_order(order, book, counter_book)
        else
          counter_book.broadcast(action: 'update', order: counter_order.attributes)
          return false
        end
      end
      return true
    end

    def add_or_cancel(order, book)
      return if order.filled?
      if order.is_a?(LimitOrder)
        book.add(order)
        AMQPQueue.enqueue(:liquidity_orders, action: 'create', source: BINANCE_SOURCE, order_id: order.id) if (Order.check_eligibility(order.id, BINANCE_SOURCE))
      elsif order.is_a?(StopOrder)
        sbook = orderbook.get_stop_book order.trigger_cond
        sbook.add(order)
        #Don't add it to the order book, and don't cancel it.
        #This order only gets canceled by the User..
      else
        publish_cancel(order, "fill or kill market order")
      end
    end

    def publish(order, counter_order, trade)
      ask, bid = order.type == :ask ? [order, counter_order] : [counter_order, order]

      price = @market.fix_number_precision :bid, trade[0]
      volume = @market.fix_number_precision :ask, trade[1]
      funds = trade[2]

      Rails.logger.info "[#{@market.id}] new trade - ask: #{ask.label} bid: #{bid.label} price: #{price} volume: #{volume} funds: #{funds}"

      @queue.enqueue(
        :trade_executor,
        { market_id: @market.id, ask_id: ask.id, bid_id: bid.id, strike_price: price, volume: volume, funds: funds },
        { persistent: false }
      )
    end

    def publish_cancel(order, reason)
      return if is_binance_orderbook(order)
      Rails.logger.info "[#{@market.id}] cancel order ##{order.id} - reason: #{reason}"
      @queue.enqueue(
        :order_processor,
        { action: 'cancel', order: order.attributes },
        { persistent: false }
      )
    end

    def is_binance_orderbook order
      order.id == ENV['BINANCE_ORDER_ID'].to_i
    end
  end
end
