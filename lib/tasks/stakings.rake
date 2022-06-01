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
        account.lock!.plus_funds(accepted_staking.interest_per_day)
        history = MemberStakeCoinCreditHistory.new
        stake_coin = accepted_staking.stake_coin
        history.member_stake_coin_id = accepted_staking.id
        history.credit_amount = accepted_staking.interest_per_day
        history.credit_percent = stake_coin.current_variable_apy.apy
        history.save
        if accepted_staking.end_date
          accepted_staking.mature! if accepted_staking.end_date < Time.zone.now
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
