class CreateLendingRedeems < ActiveRecord::Migration
  def change
    create_table :lending_redeems do |t|
      t.references :lending_subscription, index: true, foreign_key: true
      t.string :redeem_type
      t.datetime :redeem_date
      t.boolean :status, default: false

      t.timestamps null: false
    end
  end
end
