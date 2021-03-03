window.MarketTradesUI = flight.component ->
  flight.compose.mixin @, [NotificationMixin]

  @attributes
    defaultHeight: 156
    tradeSelector: 'tr'
    newTradeSelector: 'tr.new'
    allSelector: 'a.all'
    mySelector: 'a.my'
    allTableSelector: 'table.all-trades tbody'
    myTableSelector: 'table.my-trades tbody'
    newMarketTradeContent: 'table.all-trades tr.new div'
    newMyTradeContent: 'table.my-trades tr.new div'
    tradesLimit: 80

  @showAllTrades = (event) ->
    @select('mySelector').removeClass('active')
    @select('allSelector').addClass('active')
    @select('myTableSelector').hide()
    @select('allTableSelector').show()

  @showMyTrades = (event) ->
    @select('allSelector').removeClass('active')
    @select('mySelector').addClass('active')
    @select('allTableSelector').hide()
    @select('myTableSelector').show()

  @bufferMarketTrades = (event, data) ->
    @marketTrades = @marketTrades.concat data.trades

  @clearMarkers = (table) ->
    table.find('tr.new').removeClass('new')
    table.find('tr').slice(@attr.tradesLimit).remove()

  @notifyMyTrade = (trade) ->
    market = gon.markets[trade.market]
    message = gon.i18n.notification.new_trade
      .replace(/%{kind}/g, gon.i18n[trade.kind])
      .replace(/%{id}/g, trade.id)
      .replace(/%{price}/g, trade.price)
      .replace(/%{volume}/g, trade.volume)
      .replace(/%{base_unit}/g, market.base_unit.toUpperCase())
      .replace(/%{quote_unit}/g, market.quote_unit.toUpperCase())
    @notify message

  @isMine = (trade) ->
    return false if @myTrades.length == 0

    for t in @myTrades
      if trade.tid == t.id
        return true
      if trade.tid > t.id # @myTrades is sorted reversely
        return false

  @handleMarketTrades = (event, data) ->
    el = @select('allTableSelector')
    for trade in data.trades
      @marketTrades.unshift trade
      trade.classes = 'new'
      trade.classes += ' mine' if @isMine(trade)

      if(@marketTrades.length <= @attr.tradesLimit)
        el.prepend(JST['templates/market_trade'](trade))
      else
        lastTrade = $('table.all-trades tbody tr:last-child')
        @updateTrade(lastTrade, trade)
        lastTrade.remove()
        el.prepend(lastTrade)

    @marketTrades = @marketTrades.slice(0, @attr.tradesLimit)
    # @select('newMarketTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('allTableSelector'))
    , 900

  @updateTrade = (trade_element, new_trade) ->
    lastTrade = trade_element[0]
    lastTrade.id = "market-trade-"+new_trade.tid
    trade_element.addClass(new_trade.classes)
    # Trade time
    lastTrade.getElementsByClassName("time")[0].innerText = formatter.trade_time new_trade.date
    # Trade price and trend
    lastTrade.getElementsByClassName("price")[0].innerText = formatter.mask_fixed_price new_trade.price
    lastTrade.getElementsByClassName("price")[0].className = "price text-center " + formatter.trend new_trade.type
    # Trade volume and title
    lastTrade.getElementsByClassName("volume")[0].innerText = formatter.mask_fixed_volume new_trade.amount
    lastTrade.getElementsByClassName("volume")[0].title = new_trade.amount

  @updateMyTrade = (trade_element, new_trade) ->
    lastTrade = trade_element[0]
    trade_element.addClass(new_trade.classes)
    # Trade time
    lastTrade.getElementsByClassName("time")[0].innerText = formatter.fulltime new_trade.at
    # Trade price and trend
    lastTrade.getElementsByClassName("price")[0].innerText = formatter.mask_fixed_price new_trade.price
    lastTrade.getElementsByClassName("price")[0].className = "price text-center"+formatter.trend new_trade.kind
    # Trade volume and title
    lastTrade.getElementsByClassName("volume")[0].innerText = formatter.mask_fixed_volume new_trade.volume

  @handleMyTrades = (event, data, notify=true) ->
    el = @select('myTableSelector')
    for trade in data.trades
      if trade.market == gon.market.id
        @myTrades.unshift trade
        trade.classes = 'new'
        if(@myTrades.length <= @attr.tradesLimit)
          el.prepend(JST['templates/my_trade'](trade))
        else
          lastTrade = $('table.my-trades tbody tr:last-child')
          @updateMyTrade(lastTrade, trade)
          lastTrade.remove()
          el.prepend(lastTrade)

        @select('allTableSelector').find("tr#market-trade-#{trade.id}").addClass('mine')

      @notifyMyTrade(trade) if notify

    @myTrades = @myTrades.slice(0, @attr.tradesLimit) if @myTrades.length > @attr.tradesLimit
    # @select('newMyTradeContent').slideDown('slow')

    setTimeout =>
      @clearMarkers(@select('myTableSelector'))
    , 900

  @after 'initialize', ->
    @marketTrades = []
    @myTrades = []

    @on document, 'trade::populate', (event, data) =>
      @handleMyTrades(event, trades: data.trades.reverse(), false)
    @on document, 'trade', (event, trade) =>
      @handleMyTrades(event, trades: [trade])

    @on document, 'market::trades', @handleMarketTrades

    @on @select('allSelector'), 'click', @showAllTrades
    @on @select('mySelector'), 'click', @showMyTrades
