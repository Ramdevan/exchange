class CreateStakings < ActiveRecord::Migration
  def change
    create_table :stakings do |t|
      t.string :staking_type
      t.string :currency
      t.decimal :minimum_locked_amount, precision: 32, scale: 16, default: 0.0
      t.decimal :maximum_locked_amount, precision: 32, scale: 16, default: 0.0
      t.integer :redemption_period, default: 1
      t.boolean :is_active,default: true

      t.timestamps null: false
    end
  end
end
