class CreateLendingDurations < ActiveRecord::Migration
  def change
    create_table :lending_durations do |t|
      t.string :currency
      t.integer :duration_days
      t.decimal :interest_rate, precision: 8, scale: 4, default: 0.0

      t.timestamps null: false
    end
  end
end
