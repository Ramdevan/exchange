namespace :stakings do
  desc 'Add daily interest to stakings'
  task add_daily_interest: :environment do
    time = Time.zone.now
    start_of_day = Time.zone.now.beginning_of_day
    if time.between?(start_of_day - 1.hour,start_of_day + 1.hour)
      accepted_stakings = MemberStakeCoin.accepted
      accepted_stakings.each do |accepted_staking|
        unless accepted_staking.member_stake_coin_credit_histories.any?
          next if Time.zone.now - accepted_staking.start_date < 1.day
        end
        account = accepted_staking.get_account
        admin = Member.find_by_email(ENV['ADMIN'])
        admin_currency = admin.accounts.find_by_currency(account.currency)
        interest = accepted_staking.interest_per_day
        if (admin_currency.balance > interest)
          account.lock!.plus_funds(interest)
          admin_currency.sub_funds(interest)
          history = MemberStakeCoinCreditHistory.new
          stake_coin = accepted_staking.stake_coin
          history.member_stake_coin_id = accepted_staking.id
          history.credit_amount = accepted_staking.interest_per_day
          history.credit_percent = stake_coin.current_variable_apy.apy
          history.save
          if accepted_staking.end_date
            accepted_staking.mature! if accepted_staking.end_date < Time.zone.now
          end
        else
          Rails.logger.info "INFO: Insufficient balance for currency #{account.currency}"
        end
      end
    end
  end

  desc 'Process matured stakings'
  task process_matured_stakings: :environment do
    time = Time.zone.now
    start_of_day = Time.zone.now.beginning_of_day
    if time.between?(start_of_day - 1.hour,start_of_day + 1.hour)
      matured_stakings = MemberStakeCoin.matured
      matured_stakings.each do |matured_staking|
        next unless Time.zone.now - matured_staking.end_date > 1.day

        matured_staking.complete!
        stake_coin = matured_staking.stake_coin
        stake_coin.cur_lot_size -= matured_staking.amount
        stake_coin.save
      end
    end
  end
end
