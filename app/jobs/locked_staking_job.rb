class LockedStakingJob < ActiveJob::Base
  queue_as :default

  def perform
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
