namespace :stakings do
  desc 'Locked Stakings'
  task subscription: :environment do
  	locked_subscriptions = StakingLockedSubscription.locked_stakings
    locked_subscriptions.each do |subscription|
      subscription.redeem_now
    end
    defi_subscriptions = StakingLockedSubscription.defi_stakings
    defi_subscriptions.each do |subscription|
      subscription.redeem_now
    end
  end
end
