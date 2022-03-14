namespace :calculate_24h_trade_volume do
  desc 'Calculate 24h trade volume for each currency every 30 seconds'
  task  write_cache: :environment do
    while true
      begin
        Market.all.each do |market| 
          Rails.cache.write("xsea:#{market.id}_24h", Trade.with_currency(market).h24.sum(:volume))
        end
      rescue => e
        ExceptionNotifier.notify_exception(e)
      end
      sleep(600)
    end
  end
  
end