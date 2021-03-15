class Autobot

  class JSONRPCError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  # TODO: FOR TIMEBEING THESE ORDERS ARE CONSIDERED AS BINANCE ORDERS.
  # SOURCE HAS TO BE CHANGED TO BOT
  def initialize(market=nil)
    @market = market
    @source = 'Binance'
    @member = Member.first
  end

  def set_bot bot
    @bot = bot
    @market = @bot.market
  end

  def rand_percentage from=0.01, to=0.15
    rand(from..to)
  end

  def latest_market_price
    Rails.cache.fetch "latest_#{@market}_price", expires_in: 5.seconds do
	[@bot.best_price - ((@bot.best_price / 100) * rand_percentage(1,3)), @bot.best_price + ((@bot.best_price / 100) * rand_percentage(1,3))].sample
    end
  end

  def can_create_order?
    return true if @bot.start_sec.blank? || @bot.end_sec.blank?
    return if Rails.cache.read("latest_#{@market}_sec")
    Rails.cache.fetch "latest_#{@market}_sec", expires_in: rand(@bot.start_sec..@bot.end_sec).seconds do
      true
    end
  end

  def can_create_trade?
    return true if @bot.start_sec_trade.blank? || @bot.end_sec_trade.blank?
    return if Rails.cache.read("latest_#{@market}_trade_sec")
    Rails.cache.fetch "latest_#{@market}_trade_sec", expires_in: rand(@bot.start_sec_trade..@bot.end_sec_trade).seconds do
      true
    end
  end

  def random_price type, match_price=false
    latest_price = latest_market_price
    return latest_price.round(@round) if match_price
    type == 'OrderBid' ? random_bid_price(latest_price).round(@round) : random_ask_price(latest_price).round(@round)
  end

  def random_bid_price price
    # price - ((price / 100) * rand_percentage(0.01, 5.0))
    rand(@bot.min_price.to_f..@bot.best_buy.to_f)
  end

  def random_ask_price price
    # price + ((price / 100) * rand_percentage(0.01, 5.0))
    rand(@bot.best_sell.to_f..@bot.max_price.to_f)
  end

  def random_volume match_price=false
    # type == 'OrderBid' ? rand(100..10000) : rand(0.00016..0.1)
    # return rand(0.5..2.0) if match_price
    # rand(0.0016..0.4)
    # return rand(0.1..2.0) if match_price
    rand(@bot.min_vol.to_f..@bot.max_vol.to_f)
  end

  def create_orderbook bot
    set_bot bot
    return unless can_create_order?
    @round = @market[:bid]['fixed']
    update_orderbook ['OrderBid', 'OrderAsk'].sample
    # update_orderbook 'OrderBid', true
    # update_orderbook 'OrderAsk', true
  end

  def update_orderbook(type, match_price=false)
    params = { bid: @market.quote_unit,
               ask: @market.base_unit,
               state: Order::WAIT,
               currency: @market.code,
               member_id: @member.id,
               price: random_price(type, match_price),
               volume: random_volume(match_price),
               ord_type: 'limit',
               source: @source,
               id: ENV['BINANCE_ORDER_ID'].to_i }
    order = type.constantize.new params
    Rails.logger.info "#{@market.name} ORDER CREATED -- PRICE: #{order.price.to_f}, VOLUME: #{order.volume.to_f}"
    AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
  end

  def sync_trade bot
    set_bot bot
    return unless can_create_trade?
    create_trade
  end

  def create_trade
    price = latest_market_price
    volume = random_volume
    new_trade = Trade.create(price: price, volume: volume,
                             funds: (price * volume),
                             currency: @market.id,
                             trend: ['down', 'up'].sample)
    Rails.logger.info "#{@market.name} TRADE CREATED -- PRICE: #{new_trade.price.to_f}, VOLUME: #{new_trade.volume.to_f}"
    publish_trade(new_trade)
  end

  def publish_trade(trade)
    AMQPQueue.publish(
      :trade,
      trade.as_json,
      { headers: {
        market: @market.id }
      }
    )
  end
end
