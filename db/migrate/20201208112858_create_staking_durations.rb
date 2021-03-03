class CreateStakingDurations < ActiveRecord::Migration
  def change
    create_table :staking_durations do |t|
    	t.string :currency
    	t.boolean :flexible,default: false
      t.integer :duration_days
      t.decimal :estimate_apy, precision: 32, scale: 16, default: 0.0
      t.timestamps null: false
    end
  end
end
