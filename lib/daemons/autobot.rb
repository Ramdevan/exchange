# namespace :autobot do
#   task order_gen: :environment do
#     bots = Bot.where(quote_unit: 'inr', base_unit: 'btc')
#     while true
#       begin
#         autobot.sync_orderbook markets
#       rescue => e
#         puts "Error on autobot orders rake #{$!}"
#         puts $!.backtrace.join("\n")
#         sleep(1)
#       end
#     end
#   end
#
#   task trade_gen: :environment do
#     markets = Market.where(quote_unit: 'inr', base_unit: 'btc')
#     while true
#       begin
#         autobot.sync_trade markets
#       rescue => e
#         puts "Error on autobot trades rake #{$!}"
#         puts $!.backtrace.join("\n")
#         sleep(1)
#       end
#     end
#   end
#
# end

#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

Rails.logger = logger = Logger.new STDOUT

$running = true
# $running = (ENV["RAILS_ENV"] == "production")
Signal.trap("TERM") do
  $running = false
end

while($running) do
  autobot = Autobot.new
  bots = Bot.where(disabled: false)
  while true
    bots.each do |bot|
      begin
        autobot.create_orderbook bot
        autobot.sync_trade bot
      rescue => e
        ExceptionNotifier.notify_exception(e)
        puts "Error on autobot orders rake #{$!}"
        puts $!.backtrace.join("\n")
        sleep(1)
      end
    end
  end
end
