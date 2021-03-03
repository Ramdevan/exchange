namespace :lendings do
  desc 'Flexible auto transfer'
  task auto_transfer: :environment do
  	@auto_tansfers = LendingAutoTransfer.where(is_auto_transfer: true)
  	@auto_tansfers.each do |at|
  		begin
	  		member = Member.find_by(id: at.member_id)
	  		fl = Lending.find_by(id: at.lending_id)
	  		amount = fl.set_account(member).balance
	  		LendingSubscription.create(member_id: at.member_id, lending_id: at.lending_id, amount: amount, subscription_date: Date.today, is_auto_transfer: true)
  		rescue Exception => e
  			ExceptionNotifier.notify_exception(e)
      	CustomLogger.debug("Error during processing: #{$!}")
  		end
  	end
  end

  desc 'Flexible Interest rate calculate'
  task calculate_interest: :environment do
  	ydss = LendingSubscription.joins(:lending).flexibles.yesterday
  	ydss.each do |yds|
      begin
    		int_percent = yds.today_interest
    		interest_amount = ((yds.amount*int_percent)/100)
    		yds.update(interest_amount: interest_amount)
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        CustomLogger.debug("Error during processing: #{$!}")
      end
  	end
  end

  desc 'Standard redeem unlock'
  task standard_redeem: :environment do
  	frs = LendingRedeem.joins(:lending_subscription).inprogress_standard.yesterday
  	frs.each do |fr|
      begin
    		fs = fr.lending_subscription
    		fs.unlock_funds
    		account = fs.set_account
    		account.plus_funds(fs.interest_amount)
        fr.update(status: true)
        fs.update(is_completed: true)
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        CustomLogger.debug("Error during processing: #{$!}")
      end
  	end
  end

  desc 'locked Savings - Interest Calculation and unlock'
  task locked_interest_calculation: :environment do
  	lss = LendingSubscription.locked.end_subscriptions
  	lss.each do |ls|
      begin
    		ls.update(interest_amount: ls.total_interest)
    		ls.unlock_funds
    		account = ls.set_account
    		account.plus_funds(ls.interest_amount)
        ls.update(is_completed: true)
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        CustomLogger.debug("Error during processing: #{$!}")
      end
  	end
  end

  desc 'Activity Savings- Interest Calculation and unlock'
  task activity_interest_calculation: :environment do
  	ass = LendingSubscription.activities.end_subscriptions
  	ass.each do |as|
      begin
    		as.update(interest_amount: as.activity_total_interest)
    		as.unlock_funds
    		account = as.set_account
    		@account.plus_funds(as.interest_amount)
        as.update(is_completed: true)
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        CustomLogger.debug("Error during processing: #{$!}")
      end
  	end
  end
end
