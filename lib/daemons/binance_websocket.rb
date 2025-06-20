#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

Rails.logger = logger = Logger.new(STDOUT)

$running = true
Signal.trap("TERM") do 
  $running = false
  logger.info "Received TERM signal, shutting down..."
end
$running = ENV['LIQUIDITY_ENABLED'] == 'true'

if $running
  begin
    require 'json'
    valid_pairs = JSON.parse(ENV['LIQUIDITY_MARKETS'] || '{}')
  rescue => e
    logger.error "Failed to parse LIQUIDITY_MARKETS: #{e.message}"
    exit 1
  end

  Market.all.each do |market|
    pair = valid_pairs[market.id]
    next if pair.blank?
    begin
      logger.info "Starting WebSocket for market #{market.id} (pair: #{pair})"
      binance_ws = BinanceRestClient.new(market)
      binance_ws.listen_websockets
    rescue => e
      logger.error "Failed to connect WebSocket for market #{market.id}: #{e.message}"
    end
  end

  # Keep the script running until terminated
  while $running
    sleep 1
  end
  logger.info "Shutting down WebSocket connections..."
else
  logger.info "LIQUIDITY_ENABLED is not true, exiting."
end
