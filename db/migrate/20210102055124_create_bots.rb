class CreateBots < ActiveRecord::Migration
  def change
    create_table :bots do |t|
      t.string   :market_id
      t.datetime :start_time
      t.datetime :end_time
      t.integer  :start_sec
      t.integer  :end_sec
      t.integer  :start_sec_trade
      t.integer  :end_sec_trade
      t.decimal  :best_price, precision: 32, scale: 16, default: 0
      t.decimal  :min_price,  precision: 32, scale: 16, default: 0
      t.decimal  :max_price,  precision: 32, scale: 16, default: 0
      t.decimal  :best_vol,   precision: 32, scale: 16, default: 0
      t.decimal  :best_buy,   precision: 32, scale: 16, default: 0
      t.decimal  :best_sell,  precision: 32, scale: 16, default: 0
      t.decimal  :min_vol,    precision: 32, scale: 16, default: 0
      t.decimal  :max_vol,    precision: 32, scale: 16, default: 0
      t.boolean  :disabled,   default: true

      t.timestamps null: false
    end
  end
end