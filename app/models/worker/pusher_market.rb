module Worker
  class PusherMarket

    def process(payload, metadata, delivery_info)
      trade = Trade.new payload
      if trade.currency == 'ethbtc'
        trade.trigger_notify
        Global[trade.market].trigger_trades [trade.for_global]
      end  
    end

  end
end
