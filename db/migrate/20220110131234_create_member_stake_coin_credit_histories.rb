class CreateMemberStakeCoinCreditHistories < ActiveRecord::Migration
  def change
    create_table :member_stake_coin_credit_histories do |t|
      t.references :member_stake_coin
      t.decimal :credit_amount, precision: 32, scale: 16
      t.decimal :credit_percent, precision: 8, scale: 4
      t.timestamps null: false
    end
  end
end
