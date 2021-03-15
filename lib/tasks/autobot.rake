namespace :autobot do
  task order_gen: :environment do
    bots = Bot.where(quote_unit: 'inr', base_unit: 'btc')
    while true
      begin
        autobot.sync_orderbook markets
      rescue => e
        puts "Error on autobot orders rake #{$!}"
        puts $!.backtrace.join("\n")
        sleep(1)
      end
    end
  end

  task trade_gen: :environment do
    markets = Market.where(quote_unit: 'inr', base_unit: 'btc')
    while true
      begin
        autobot.sync_trade markets
      rescue => e
        puts "Error on autobot trades rake #{$!}"
        puts $!.backtrace.join("\n")
        sleep(1)
      end
    end
  end

end
