class CreateLendingSubscriptions < ActiveRecord::Migration
  def change
    create_table :lending_subscriptions do |t|
      t.references :member, index: true, foreign_key: true
      t.references :lending, index: true, foreign_key: true
      t.references :lending_duration, index: true, foreign_key: true
      t.decimal :amount, precision: 32, scale: 16, default: 0.0
      t.date :subscription_date
      t.decimal :interest_amount, precision: 8, scale: 4, default: 0.0
      t.boolean :is_auto_transfer, default: false
      t.boolean :is_completed, default: false
      t.boolean :is_auto_renew, default: false
      t.datetime :start_date
      t.datetime :end_date

      t.timestamps null: false
    end
  end
end
