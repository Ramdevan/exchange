@HeaderUI = flight.component ->
  @attributes
    vol: 'p.vol'
    amount: 'p.amount'
    high: 'p.high'
    low: 'p.low'
    change: 'p.change'
    last: 'p.last'
    sound: 'input[name="sound-checkbox"]'

  @refresh = (event, ticker) ->
    @select('vol').text("#{ticker.volume} #{gon.market.base_unit.toUpperCase()}")
    @select('high').text(ticker.high)
    @select('low').text(ticker.low)
    @select('last').text(ticker.last)

    p1 = parseFloat ticker.open
    p2 = parseFloat ticker.last
    trend = formatter.trend(p1 <= p2)
    @select('change').html("<p class='#{trend}'>#{formatter.price_change(p1, p2)}%</p>")

  @after 'initialize', ->
    @on document, 'market::ticker', @refresh

    if Cookies.get('sound') == undefined
      Cookies.set('sound', true, 30)
    state = Cookies.get('sound') == 'true' ? true : false

    @select('sound').bootstrapSwitch
      labelText: gon.i18n.switch.sound
      state: state
      handleWidth: 40
      labelWidth: 40
      onSwitchChange: (event, state) ->
        Cookies.set('sound', state, 30)

    $('header .dropdown-menu').click (e) ->
      e.stopPropagation()
