require 'httparty'

namespace :calculate_volume do
  desc 'Calculate volume traded by a user for the last 30 days'
  task for_30_days: :environment do
    CustomLogger.debug("Starting to run")
    begin
      Member.all.each do |member|
        CustomLogger.debug("Starting to read #{member.id}")
        trade_volume = Trade.get_trading_volume(member.id, (Time.now - 30.days), Time.now).to_d
        member.update(trade_volume: trade_volume.nil? ? 0 : trade_volume)
        CustomLogger.debug("Trade Volume - #{trade_volume}")
      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
      CustomLogger.debug("Error during processing: #{$!}")
    end
  end
end