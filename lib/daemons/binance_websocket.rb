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

if $running

  valid_pairs = eval(ENV['LIQUIDITY_MARKETS'])

  Market.all.each do |market|

    pair = valid_pairs[market.id]
    next if pair.blank?

    binance_ws = BinanceRestClient.new(market)
    binance_ws.listen_websockets

  end
end
