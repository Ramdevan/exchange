@AccountSummaryUI = flight.component ->
  @attributes
    total_assets: '#total_assets'

  @updateAccount = (event, data) ->
    for currency, account of data
      amount = (new BigNumber(account.locked)).plus(new BigNumber(account.balance))
      @$node.find("tr.#{currency} span.amount").text(formatter.round(amount, 2))
      @$node.find("tr.#{currency} span.locked").text(formatter.round(account.locked, 2))

  @updateTotalAssets = ->
    # @select('total_assets').text "#{formatter.round(gon.current_user.total_balance, 4)} #{gon.current_user.conversion_unit}"

  @after 'initialize', ->
    @accounts = gon.accounts
    @tickers  = gon.tickers

    @on document, 'account::update', @updateAccount

    @on document, 'account::update', (event, data) =>
      @accounts = data
      @updateTotalAssets()

    @on document, 'market::tickers', (event, data) =>
      @tickers = data.raw
      @updateTotalAssets()


