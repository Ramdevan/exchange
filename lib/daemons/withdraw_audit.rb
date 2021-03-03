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
  Withdraw.submitted.each do |withdraw|
    begin
      withdraw.audit!
    rescue => e
      puts "Error on withdraw audit: #{$!}"
      puts $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception(e)
    end
  end

  sleep 5
end
