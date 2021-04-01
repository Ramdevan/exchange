class Autobot

  class JSONRPCError < RuntimeError; end
  class ConnectionRefusedError < StandardError; end

  # TODO: FOR TIMEBEING THESE ORDERS ARE CONSIDERED AS BINANCE ORDERS.
  # SOURCE HAS TO BE CHANGED TO BOT
  def initialize(market=nil)
    @markets = eval(ENV['BOT_MARKETS'])
    @source = 'Binance'
    @member = Member.find_by_email(ENV['BINANCE_USER'])
  end

  def latest_market_price market
    Rails.cache.read("citioption:#{@markets[market.id]}:ticker")[:last] rescue Trade.latest_price(@markets[market.id].to_sym)
  end

  def random_price market, type, match_price=false
    latest_price = latest_market_price market
    return latest_price.round(market[:bid]['fixed']) if match_price
    type == 'OrderBid' ? random_bid_price(latest_price).round(market[:bid]['fixed']) : random_ask_price(latest_price).round(market[:bid]['fixed'])
  end

  def random_bid_price price
    price - ((price / 100) * rand(0.01..5.0))
  end

  def random_ask_price price
    price + ((price / 100) * rand(0.01..5.0))
  end

  def random_volume market, match_price=false
    return rand(eval(market[:volume_range]['max'])) if match_price
    rand(eval(market[:volume_range]['min']))
  end

  def sync_orderbook markets
    markets.each do |market|
      next if @markets[market.id].blank?
      rand(1..10).times{|i|
        update_orderbook market, ['OrderBid', 'OrderAsk'].sample
        sleep rand(0.1..2.0)
      }
      update_orderbook market, 'OrderBid', true
      update_orderbook market, 'OrderAsk', true
    end
  end

  def update_orderbook(market, type, match_price=false)
    params = { bid: market.quote_unit,
               ask: market.base_unit,
               state: Order::WAIT,
               currency: market.code,
               member_id: @member.id,
               price: random_price(market, type, match_price),
               volume: random_volume(market, match_price),
               ord_type: 'limit',
               source: @source,
               id: ENV['BINANCE_ORDER_ID'].to_i }
    order = type.constantize.new params
    AMQPQueue.enqueue(:matching, action: 'submit', order: order.to_matching_attributes)
  end

  def sync_trade markets
    markets.each do |market|
      next if @markets[market.id].blank?
      create_trade(market)
      sleep rand(1..10)
    end
  end

  def create_trade market
    price = latest_market_price market
    volume = random_volume market
    new_trade = Trade.create(price: price, volume: volume,
                             funds: (price * volume),
                             currency: market.id,
                             trend: ['down', 'up'].sample)
    publish_trade(new_trade, market)
  end

  def publish_trade(trade, market)
    AMQPQueue.publish(
      :trade,
      trade.as_json,
      { headers: {
        market: market.id }
      }
    )
  end
end
