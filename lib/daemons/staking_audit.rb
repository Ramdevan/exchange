#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "production"

root = File.expand_path(File.dirname(__FILE__))
root = File.dirname(root) until File.exists?(File.join(root, 'config'))
Dir.chdir(root)

require File.join(root, "config", "environment")

$running = (ENV["RAILS_ENV"] == "production")
Signal.trap("TERM") do
  $running = false
end

while($running) do
  MemberStakeCoin.submitted.each do |member_stake_coin|
    begin
        member_stake_coin.audit!
    rescue => e
      puts "Error on staking audit: #{$!}"
      puts $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception(e)
    end
  end

  sleep 5
end
