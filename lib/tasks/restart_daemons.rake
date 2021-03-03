namespace :restart do
  desc 'Restart Daemons if its down'
  task  daemons: :environment do
    skip_daemons = []
    while true
      begin
        Daemons::Rails::Monitoring.controllers.each{|controller|
          next if skip_daemons.include?(controller.app_name) || controller.status == :running
          controller.start
        }
      rescue => e
        ExceptionNotifier.notify_exception(e)
        puts "Error on Restating Daemons #{$!}"
        puts $!.backtrace.join("\n")
      end
      sleep(300)
    end
  end
  
end
