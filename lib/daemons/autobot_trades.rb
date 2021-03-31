#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = true
Signal.trap("TERM") do 
  $running = false
end
$running = ENV['BOT_ENABLED'] == 'true'

while($running) do

  autobot = Autobot.new
  markets = Market.where(quote_unit: 'citiusd')
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
