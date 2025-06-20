#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do
  $running = false
end

while($running) do
  all_tickers = {}
  market_pairs = {}
  begin
    Market.all.each do |market|
      unless market_pairs.has_key? market.quote_unit
        market_pairs[market.quote_unit] = []
      end
      global = Global[market.id]
      global.trigger_orderbook
      all_tickers[market.id] = market.unit_info.merge(global.ticker)
      market_pairs[market.quote_unit].push(market.details)
    end
    Global.trigger 'tickers', all_tickers
    Global.trigger 'mobile-tickers', market_pairs
  rescue => e
    ExceptionNotifier.notify_exception(e)
    puts "Error on Global State #{$!}"
    puts $!.backtrace.join("\n")
    next
  end
  sleep 5
end
