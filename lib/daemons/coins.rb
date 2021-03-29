#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

running = (ENV["RAILS_ENV"] == "production")
Signal.trap(:TERM) { running = false }

def load_transactions(coin)
  txs = []

  case coin.code
  when 'eth', 'usdt', 'citiusd', 'mana', 'enj'
    CoinRPC[coin.code].listtransactions
  else
    txs = CoinRPC[coin.code].listtransactions('payment', 100)
  end
  txs
rescue => e
  ExceptionNotifier.notify_exception(e)
  Rails.logger.fatal e.inspect
  [] # Fallback with empty transaction list.
end


def get_attrs_for_coins coin_code, tx
  address = CoinRPC[coin_code].to_legacy_address(tx['address']) rescue tx['address']
  [tx['category'], tx['txid'], address]
end

def process_transaction(coin, channel, tx)

  category, txid, address = get_attrs_for_coins(coin.code, tx)
  return if category != 'receive'

  # Skip if transaction exists.
  return if PaymentTransaction::Normal.where(txid: txid).exists?

  # Skip zombie transactions (for which addresses don't exist).
  return unless PaymentAddress.where(address: address).exists?

  Rails.logger.info "Missed #{coin.code.upcase} transaction: #{txid}."

  # Immediately enqueue job.
  AMQPQueue.enqueue :deposit_coin, {txid: txid, channel_key: channel.key}
rescue => e
  ExceptionNotifier.notify_exception(e)
  Rails.logger.fatal e.inspect
end

while running
  channels = DepositChannel.all.each_with_object({}) { |ch, memo| memo[ch.currency] = ch }
  coins = Currency.where(coin: true)

  coins.each do |coin|
    next unless (channel = channels[coin.code])

    load_transactions(coin).each do |tx|
      break unless running
      process_transaction(coin, channel, tx)
    end
  end

  Kernel.sleep 5
end
