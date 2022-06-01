class RemoveOldStakingTables < ActiveRecord::Migration
  def change
    drop_table :staking_locked_subscriptions
    drop_table :staking_locked_durations
    drop_table :staking_durations
    drop_table :stakings
  end
end
