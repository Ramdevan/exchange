class CreateMemberStakeCoins < ActiveRecord::Migration
  def change
    create_table :member_stake_coins do |t|
      t.references :member
      t.references :stake_coin
      t.decimal :amount, precision: 32, scale: 16
      # t.decimal :interest_per_day, precision: 32, scale: 16
      t.string :aasm_state
      t.datetime :start_date
      t.datetime :end_date
      t.timestamps null: false
    end
  end
end
