class CreateStakeCoins < ActiveRecord::Migration
  def change
    create_table :stake_coins do |t|
      t.integer :currency
      t.decimal :min_deposit, precision: 32, scale: 16
      t.decimal :max_deposit, precision:32, scale: 16
      t.integer :duration
      t.integer :variable_apy_id
      t.decimal :max_lot_size, precision: 32, scale: 16
      t.decimal :cur_lot_size, precision: 32, scale: 16, default: 0.0
      t.decimal :lot_size_for_apy, precision: 32, scale: 16, default: 0.0
      t.boolean :is_flexible, default: false
      t.boolean :is_active, default: true
      t.timestamps null: false
    end
  end
end
