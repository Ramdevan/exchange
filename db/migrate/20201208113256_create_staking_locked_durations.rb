class CreateStakingLockedDurations < ActiveRecord::Migration
  def change
    create_table :staking_locked_durations do |t|
    	t.belongs_to :staking
      t.belongs_to :staking_duration
      t.timestamps null: false
    end
  end
end
