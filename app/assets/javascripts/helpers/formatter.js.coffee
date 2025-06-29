class Formatter
  round: (str, fixed) ->
    BigNumber(str).round(fixed, BigNumber.ROUND_HALF_UP).toF(fixed)

  fix: (type, str) ->
    str = '0' unless $.isNumeric(str)
    if type is 'ask'
      @.round(str, gon.market.ask.fixed)
    else if type is 'bid'
      @.round(str, gon.market.bid.fixed)

  fixAmount: (type, str) ->
    str = '0' unless $.isNumeric(str)
    if type is 'ask'
      @.round(str, (gon.market.price_precision||gon.market.ask.fixed))
    else if type is 'bid'
      @.round(str, (gon.market.price_precision||gon.market.bid.fixed))

  fixAsk: (str) ->
    @.fix('ask', str)

  fixBid: (str) ->
    @.fix('bid', str)

  fixPriceGroup: (str) ->
    if gon.market.price_precision
      str = '0' unless $.isNumeric(str)
      @.round(str, gon.market.price_precision)
    else
      @fixBid(str)

  check_trend: (type) ->
    if type == 'up' or type == 'buy' or type == 'bid' or type == true
      true
    else if type == 'down' or type == "sell" or type = 'ask' or type == false
      false
    else
      throw "unknown trend smybol #{type}"

  market: (base, quote) ->
    "#{base.toUpperCase()}/#{quote.toUpperCase()}"

  market_url: (market, order_id) ->
    if order_id?
      "/markets/#{market}/orders/#{order_id}"
    else
      "/markets/#{market}"

  trade: (ask_or_bid) ->
    gon.i18n[ask_or_bid]

  short_trade: (type) ->
    if type == 'buy' or type == 'bid'
      'Buy'
    else if type == "sell" or type = 'ask'
      'Sell'
    else
      'n/a'

  trade_time: (timestamp) ->
    m = moment.unix(timestamp)
    "#{m.format("HH:mm")}#{m.format(":ss")}"

  fulltime: (timestamp) ->
    m = moment.unix(timestamp)
    "#{m.format("MM/DD HH:mm")}"

  mask_price: (price) ->
    price.replace(/\..*/, "<g>$&</g>")

  mask_fixed_price: (price) ->
    @fixPriceGroup(price)

  ticker_fill: ['', '0', '00', '000', '0000', '00000', '000000', '0000000', '00000000']
  ticker_price: (price, fillTo=6) ->
    [left, right] = price.split('.')
    if fill = @ticker_fill[fillTo-right.length]
      "#{left}.#{right}#{fill}"
    else
      "#{left}.#{right.slice(0,fillTo)}"

  price_change: (p1, p2) ->
    percent = if p1
                @round(100*(p2-p1)/p1, 2)
              else
                '0.00'
    "#{if p1 > p2 then '' else '+'}#{percent}"

  long_time: (timestamp) ->
    m = moment.unix(timestamp)
    "#{m.format("YYYY/MM/DD HH:mm")}"

  mask_fixed_volume: (volume) ->
    @.fixAsk(volume)

  fix_ask: (volume) ->
    @.fixAsk volume

  fix_bid: (price) ->
    @.fixBid price

  mask_fixed_amount: (amount, price, type='ask') ->
    val = (new BigNumber(amount)).times(new BigNumber(price))
    @.fixAmount(type, val)

  amount: (amount, price) ->
    val = (new BigNumber(amount)).times(new BigNumber(price))
    @.fixAsk(val)

  trend: (type) ->
    if @.check_trend(type)
      "text-up"
    else
      "text-down"

  trend_icon: (type) ->
    if @.check_trend(type)
      "<i class='fa fa-caret-up text-up'></i>"
    else
      "<i class='fa fa-caret-down text-down'></i>"

  t: (key) ->
    gon.i18n[key]

window.formatter = new Formatter()
