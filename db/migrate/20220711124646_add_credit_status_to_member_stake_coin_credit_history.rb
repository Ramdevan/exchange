class AddCreditStatusToMemberStakeCoinCreditHistory < ActiveRecord::Migration
  def change
    add_column :member_stake_coin_credit_histories, :credit_status, :string
  end
end
