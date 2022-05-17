namespace :calculate_24h_trade_volume do
  desc 'Calculate 24h trade volume for each currency every 30 seconds'
  task  write_cache: :environment do
    begin
      Market.all.each do |market|
        base_volume = quote_volume = 0
        Trade.with_currency(market).h24.each do |trade|
          base_volume += trade.volume
          quote_volume += trade.funds
        end
        base_volume = base_volume.round(market[:bid]["fixed"])
        quote_volume = quote_volume.round(market[:ask]["fixed"])
        Rails.cache.write("xubiq:#{market.id}_24h", base_volume)
        Rails.cache.write("xubiq:#{market.id}_24h_volumes", {base_volume: base_volume, quote_volume: quote_volume})
      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
    end
  end
end