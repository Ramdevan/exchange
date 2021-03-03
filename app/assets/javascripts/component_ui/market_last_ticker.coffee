window.MarketLastTickerUI = flight.component ->
  @attributes
    lastSelector: '.last .price'
    priceSelector: '.price'

  @updatePrice = (selector, price, trend) ->
    selector.removeClass('text-up').removeClass('text-down').addClass(formatter.trend(trend))
    selector.html(formatter.fixBid(price))

  @refresh = (event, ticker) ->
    @updatePrice @select('lastSelector'), ticker.last, ticker.last_trend

  @after 'initialize', ->
    @on document, 'market::ticker', @refresh