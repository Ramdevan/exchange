#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

Rails.logger = logger = Logger.new STDOUT

$running = true
Signal.trap("TERM") do
  $running = false
end
$running = ENV['LIQUIDITY_ENABLED'] == 'true'

while($running) do
  begin
    binance = BinanceRestClient.new
    binance.sync_orderbook
    binance.websocket_update_orderbook
  rescue => e
    ExceptionNotifier.notify_exception(e)
    puts "Error on SyncOrder #{$!}"
    puts $!.backtrace.join("\n")
    next
  end
end
