class CreateLendings < ActiveRecord::Migration
  def change
    create_table :lendings do |t|
      t.string :currency
      t.decimal :today_apy, precision: 8, scale: 4, default: 0.0
      t.decimal :yesterday_apy, precision: 8, scale: 4, default: 0.0
      t.date :published_on
      t.decimal :max_subscription_amount, precision: 32, scale: 16, default: 0.0
      t.integer :lot_size
      t.integer :max_lot_size
      t.string :name
      t.integer :lending_type_id
      t.decimal :interest_rate, precision: 8, scale: 4, default: 0.0
      t.integer :duration_days

      t.timestamps null: false
    end
  end
end
