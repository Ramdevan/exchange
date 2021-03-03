class CreateStakingLockedSubscriptions < ActiveRecord::Migration
  def change
    create_table :staking_locked_subscriptions do |t|
    	t.references :member, index: true, foreign_key: true
      t.references :staking_locked_duration, index: true, foreign_key: true
      t.references :staking, index: true, foreign_key: true
      t.decimal :amount, precision: 32, scale: 16, default: 0.0
      t.decimal :interest_percentage, precision: 8, scale: 4, default: 0.0
      t.decimal :interest_amount, precision: 32, scale: 16, default: 0.0
      t.string :status
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps null: false
    end
  end
end
