require 'binance'
require 'eventmachine'

class BinanceRestClient

  class JSONRPCError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  def initialize(market=nil)
    @client = Binance::Client::REST.new api_key: ENV['BINANCE_KEY'],
                                        secret_key: ENV['BINANCE_SECRET']
    @websocket = Binance::Client::WebSocket.new
    @market = market
    @markets = Market.all.group_by(&:id)
    @source = 'Binance'
    @member = Member.find_by_email(ENV['BINANCE_USER'])
  end

  def pairs
    eval(ENV['LIQUIDITY_MARKETS'])
  end

  ######################################################################################
  ### sync_orderbook METHODS IS FOR FETCHING AND INITILIZING ORDERBOOK FOR FIRSTTIME ###
  ######################################################################################

  def sync_orderbook
    Market.all.each do |market|

      pair = pairs[market.id]
      next if pair.blank?
      params = {symbol: pair, limit: 50}
      orders = @client.depth params
      Rails.cache.delete "citioption:#{market}:depth:asks"
      Rails.cache.delete "citioption:#{market}:depth:bids"
      update_orderbook market, orders['bids'], 'OrderBid'
      update_orderbook market, orders['asks'], 'OrderAsk'
    end
  end

  def update_orderbook(market, orders, type)
    return if orders.blank?
    orders.each do |order_param|
      params = { bid: market.quote_unit,
                 ask: market.base_unit,
                 state: Order::WAIT,
                 currency: market.code,
                 member_id: @member.id,
                 price: order_param[0].to_d,
                 volume: order_param[1].to_d,
                 ord_type: 'limit',
                 source: @source,
                 id: ENV['BINANCE_ORDER_ID'].to_i }

      order = type.constantize.new params
      begin
        cancel_binance_orderbook order
        #puts "Cancelled #{type} with Price #{order_param[0]}"
        AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        Rails.logger.error e
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  def cancel_binance_orderbook order
    AMQPQueue.enqueue(:matching, action: 'cancel', order: order.to_matching_attributes)
  end

  ### AFTER FIRSTTIME, WEBSOCKET UPDATE FOR ORDERBOOK ###

  def websocket_update_orderbook
    begin
      EM.run do
        # Create event handlers
        open    = proc { puts 'connected' }
        message = proc { |e|
          data = JSON.parse(e.data)
          market = @markets[pairs.key(data['s'].upcase)].first
          # puts data
          update_orderbook(market, data['a'], 'OrderAsk') if data['a'].present?
          update_orderbook(market, data['b'], 'OrderBid') if data['b'].present?
        }
        error   = proc { |e| puts e }
        close   = proc { puts 'closed' }

        # Bundle our event handlers into Hash
        methods = { open: open, message: message, error: error, close: close }

        # Pass a symbol and event handler Hash to connect and process events
        pairs.each do |pair|
          @websocket.diff_depth symbol: pair[1], methods: methods
        end

      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
      puts "Error on Creating trade #{$!}"
      puts $!.backtrace.join("\n")
    end
  end

  #####################################################################
  ### BELOW METHODS ARE FOR PLACING AND CANCELING ORDERS IN BINANCE ###
  #####################################################################

  def place_binance_order order_params
    params = { symbol: pairs[@market.id],
               side: order_params[:side] == 'OrderBid' ? 'BUY' : 'SELL',
               type: 'LIMIT',
               timeInForce: 'GTC',
               quantity: order_params[:quantity],
               price: order_params[:price],
               recvWindow: 30000 }
    @client.create_order! params
  end

  def cancel_binance_order binance_order_id
    params = { symbol: pairs[@market.id],
               orderId: binance_order_id,
               recvWindow: 30000 }
    @client.cancel_order! params
  end

  #####################################################################################
  ### BELOW METHODS ARE TO UPDATE WEBSOCKET RESPONSE FOR *ORDERS PLACED IN BINANCE* ###
  #####################################################################################

  def listen_websockets
    listen_key = @client.listen_key['listenKey']

    open    = proc { puts 'connected' }
    message = proc { |e| update_from_websocket(JSON.parse(e.data), :message) }
    error   = proc { |e| update_from_websocket(JSON.parse(e.data), :error) }
    close   = proc { puts 'closed' }

    # Bundle our event handlers into Hash
    methods = { open: open, message: message, error: error, close: close }

    EM.run do
      @websocket.user_data listen_key: listen_key, methods: {message: message}
    end
  end

  def update_from_websocket data, type
    data = data.symbolize_keys!
    liquidity_status = LiquidityStatus.where(liquid_id: data[:i]).first
    return unless liquidity_status
    case data[:x]
      when 'NEW'
        # As it will be already created when order is placed internally
        # Orders place in binance should not be created internally
      when 'CANCELED'
        # cancel_orders liquidity_status.order
      when 'TRADE'
        fill_orders liquidity_status.order, {price: data[:p], quantity: data[:l], side: data[:S]}
      else
    end
    update_liquidity_status liquidity_status, data[:X], data
  end


  def cancel_orders existing_orders, hard_delete=false
    existing_orders ||= @member.orders.where(source: @source).with_currency(@market).with_state(:wait)
    Ordering.new(existing_orders).cancel
    # TODO: Check if its required to delete existing unwanted
    # records, as it may will dumb DB without deleting
    # existing_orders.delete_all if hard_delete
  end

  def fill_orders(order, detail, cross_order=false)
    return unless order.state == Order::WAIT
    price = convert_to_decimal detail[:price]
    quantity = convert_to_decimal detail[:quantity]
    funds = price * quantity
    params = {price: price, volume: quantity, funds: funds,
              currency: @market.id.to_sym, trend: trend(price)}
    detail[:side] == 'BUY' ? params.merge!({bid_id: order.id, bid_member_id: order.member_id}) : params.merge!({ask_id: order.id, ask_member_id: order.member_id})
    trade = Trade.create!(params)
    order.strike(trade, ENV['BINANCE_TRADE_FEE'].to_f, cross_order)
  end

  def trend price
    price >= @market.latest_price ? 'up' : 'down'
  end

  ###############################################################################
  ### update_orders IS A FALLBACK METHOD TO UPDATE ORDERS IF WEBSOCKET FAILED ###
  ###############################################################################

  def update_orders
    pending_order_ids = LiquidityStatus.pending.map(&:liquid_id)
    return if pending_order_ids.blank?
    params = { symbol: pairs[@market.id], orderId: pending_order_ids.first, recvWindow: 30000 }
    all_orders = @client.all_orders(params)
    return if all_orders.blank?
    all_orders.each{ |data|
      next unless pending_order_ids.include? data['orderId']
      liquidity_status = LiquidityStatus.where(liquid_id: data['orderId']).first
      next unless liquidity_status
      case data['status']
        when 'CANCELED'
          cancel_orders liquidity_status.order
        when 'FILLED'
          fill_orders liquidity_status.order, {price: data['price'], quantity: data['executedQty'], side: data['side']}
      end
      update_liquidity_status liquidity_status, data['status'], data
    }
  end

  def update_liquidity_status liquidity_status, state, data
    liquidity_status.update_attributes(state: state)
    liquidity_status.liquidity_histories.create(detail: data)
  end

  def convert_to_decimal val
    val.to_d
  end

  #########################################################
  ### BELOW METHODS ARE UPDATING TRADES WITH WEBSOCKETS ###
  #########################################################

  def sync_trade_by_websocket
    begin
      EM.run do
        open    = proc { puts 'connected' }
        message = proc { |e|
          #puts e.data
          data = JSON.parse(e.data)
          create_trade(data)
        }
        error   = proc { |e| puts e }
        close   = proc { puts 'closed' }
        methods = { open: open, message: message, error: error, close: close }
        pairs.each do |pair|
          @websocket.agg_trade symbol: pair[1], methods: methods
        end

      end
    rescue => e
      #ExceptionNotifier.notify_exception(e)
      puts "Binance Trade Websocket -- Error on Creating trade #{$!}"
      puts $!.backtrace.join("\n")
    end
  end

  def create_trade trade
    market = @markets[pairs.key(trade['s'].upcase)].first
    return if Rails.cache.read("citioption:#{market.id}:push_binance_trade").present?
    new_trade = Trade.create(price: trade['p'],
                             volume: trade['q'],
                             funds: trade['p'].to_f * trade['q'].to_f,
                             currency: market.id,
                             trend: trade['m'] == true ? 'down' : 'up')
    publish_trade(new_trade, market)
  end

  def publish_trade(trade, market=nil)
    market ||= @market
    Rails.cache.write("citioption:#{market.id}:push_binance_trade", true, expires_in: rand(1..5).seconds)
    AMQPQueue.publish(
      :trade,
      trade.as_json,
      { headers: {
        market: market.id
      }
      }
    )
  end
end
