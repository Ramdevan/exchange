class MemberStakeCoinCreditHistory < ActiveRecord::Base
    belongs_to :member_stake_coin

    def self.pending_interest
        where(credit_status: "Pending")
    end
end
