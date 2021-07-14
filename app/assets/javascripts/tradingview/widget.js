function getLanguageFromURL() {
	const regex = new RegExp('[\\?&]lang=([^&#]*)');
	const results = regex.exec(location.search);

	return results === null ? null : decodeURIComponent(results[1].replace(/\+/g, ' '));
}

class Datafeed {
  constructor(options) {
      this.Host = location.origin
      this.debug = options.debug || false
  }

  ServerTime() {
      const url = this.Host + '/api/v2/time'
      return fetch(url).then(res => {
          return res.json()
      }).then(json => {
          return json.serverTime
      })
  }

  exchangeSymbols() {
      const url = this.Host + '/api/v2/markets'
      //return fetch('http://localhost:9090/api/v1/exchangeInfo').then(res => {
      return fetch(url).then(res => {
          return res.json()
      }).then(json => {
          return json
      })
  }

  klines(symbol, interval, startTime, endTime, limit) {
      const url = this.Host + '/api/v2/k.json' +
           "?market=".concat(symbol).toLowerCase() +
           "&period=".concat(interval) +
           "&limit=".concat(limit) +
           "&timestamp=".concat(startTime) +
          "&endtimestamp=".concat(endTime)
      return fetch(url).then(res => {
          return res.json()
      }).then(json => {
          return json

      })
  }

  onReady(callback) {
      this.exchangeSymbols().then((symbols) => {
          this.symbols = symbols
          callback({
              supports_marks: false,
              supports_timescale_marks: false,
              supports_time: true,
              supported_resolutions: [
                  '1', '5', '15', '60', '720', '1D', '1W'
              ]
          })
      }).catch(err => {
          console.error(err)
      })
  }

  resolveSymbol(symbolName, onSymbolResolvedCallback, onResolveErrorCallback) {

      const comps = symbolName.split(':')
      symbolName = (comps.length > 1 ? comps[1] : symbolName).toUpperCase()

      for (let symbol of this.symbols) {
          if (symbol.id.toUpperCase() == symbolName) {
            
              setTimeout(() => {
                  onSymbolResolvedCallback({
                      name: symbol.id.toUpperCase(),
                      description: symbol.base_unit.toUpperCase() + ' / ' + symbol.quote_unit.toUpperCase(),
                      ticker: symbol.id,
                      exchange: 'Ioio',
                      listed_exchange: 'Ioio',
                      //type: 'crypto',
                      session: '24x7',
                      minmov: 1,
                      pricescale: 10000000,
                      timezone: 'Asia/Seoul',
                      has_intraday: true,
                      has_daily: true,
                      has_weekly_and_monthly: true,
                      currency_code: symbol.quote_unit.toUpperCase()
                  })
              }, 0)
              return
          }
      }

      onResolveErrorCallback('not found')
  }

  getBars(symbolInfo, resolution, from, to, onHistoryCallback, onErrorCallback, firstDataRequest) {
      if (this.debug) {
          console.log('')
          console.log('ðŸ‘‰ getBars:', symbolInfo.name, resolution)
          console.log('First:', firstDataRequest)
          console.log('From:', from, '(' + new Date(from * 1000).toGMTString() + ')')
          console.log('To:  ', to, '(' + new Date(to * 1000).toGMTString() + ')')
      }

      const interval = {
          '1': '1',
          '5': '5',
          '15': '15',
          '60': '60',
          '720': '720',
          '1D': '1440',
          '1W': '10080',
      }[resolution]

      if (!interval) {
          onErrorCallback('Invalid interval')
      }

      let totalKlines = []

      const finishKlines = () => {
          if (this.debug) {
              console.log('ðŸ“Š:', totalKlines.length)
          }

          if (totalKlines.length == 0) {
              onHistoryCallback([], { noData: true })
          } else {
              onHistoryCallback(totalKlines.map(kline => {
                  return {
                      time: kline[0] * 1000,
                      close: parseFloat(kline[4]),
                      open: parseFloat(kline[1]),
                      high: parseFloat(kline[2]),
                      low: parseFloat(kline[3]),
                      volume: parseFloat(kline[5])
                  }
              }), {
                      noData: false
                  })
          }
      }

      const getKlines = (from, to) => {
          this.klines(symbolInfo.name, interval, from, to, 500).then(klines => {
                totalKlines = totalKlines.concat(klines)

                if (klines.length == 500) {
                    from = klines[klines.length - 1][0] + 1
                    getKlines(from, to)
                } else {
                    finishKlines()
                }
          }).catch(err => {
              onErrorCallback('Some problem')
          })
      }

      getKlines(from, to)
  }

  subscribeBars(symbolInfo, resolution, onRealtimeCallback, subscriberUID, onResetCacheNeededCallback) {
        this.debug && console.log('👉 subscribeBars:', subscriberUID)
        let channel = pusher.channels.channels["market-"+symbolInfo.ticker+"-global"]

        channel.bind("chart-ticker-"+resolution, function(data) {
            let last_ts = data[0] * 1000
            onRealtimeCallback({time: next_ts(last_ts, resolution), close: data[4], open: data[1], high: data[2], low: data[3], volume: data[5]})
        })

  }

  unsubscribeBars(subscriberUID) {
      this.debug && console.log('ðŸ‘‰ unsubscribeBars:', subscriberUID)
  }

  getServerTime(callback) {
      this.ServerTime().then(time => {
          callback(Math.floor(time / 1000))
      }).catch(err => {
          console.error(err)
      })
  }
}

TradingView.onready(function() {
	var widget = window.tvWidget = new TradingView.widget({
        symbol: gon.market.id.toUpperCase(),
        // BEWARE: no trailing slash is expected in feed URL
        // tslint:disable-next-line:no-any
        datafeed: new Datafeed({ debug: false }),
        interval: '5',
        timezone: "Asia/Seoul",
        container_id: 'tv_chart_container',
        library_path: '/assets/charting_library/',

        locale: getLanguageFromURL() || 'en',
        disabled_features: ['use_localstorage_for_settings'],
        //enabled_features: ['study_templates'],
        //charts_storage_url: 'https://saveload.tradingview.com',
        //charts_storage_api_version: '1.1',
        client_id: 'tradingview.com',
        user_id: 'public_user_id',
        fullscreen: false,
        autosize: true,
        debug: false,
        theme: 'dark'
	});

});

function next_ts(ts, period) {
    milli_secs = period * 60 * 1000

    return ts + milli_secs
}
