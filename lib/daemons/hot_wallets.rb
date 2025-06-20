#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = (ENV["RAILS_ENV"] == "development")
Signal.trap("TERM") do
  $running = false
end

while($running) do
  Currency.all.each do |currency|
    begin
      currency.refresh_balance if currency.coin?
    rescue => e
      ExceptionNotifier.notify_exception(e)
      puts "Error in Hit wallet Daemon #{$!}"
      puts $!.backtrace.join("\n")
      next
    end
  end

  sleep 5
end
