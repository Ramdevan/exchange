class AddPublishedOnToStakings < ActiveRecord::Migration
  def change
  	add_column :stakings, :published_on, :date
  	add_column :staking_locked_subscriptions, :staking_duration_id, :integer
  end
end
