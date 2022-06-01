# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
set :output, "log/referral.log"

#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# every 1.hours do
#   command '/usr/local/rbenv/shims/backup perform -t database_backup'
# end
#
# every :day, at: '4am' do
#   rake 'solvency:clean solvency:liability_proof'
# end

every :day, at: '11:59' do
  rake 'calculate_volume:for_30_days'
end

every :day, at: '00:15' do
        rake 'stakings:add_daily_interest'
end

every :day, at: '05:00' do
        rake 'stakings:process_matured_stakings'
end

every 10.minutes do
  rake 'calculate_24h_trade_volume:write_cache'
end