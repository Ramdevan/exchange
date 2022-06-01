module APIv2
    module Entities
      class MemberStakeCoin < Base
        expose :id
        expose :amount, as: :invested_amount, documentation: "Total number of coins invested in the plan."
        expose :aasm_state, as: :state, documentation: "Status of the documentation."
        expose :stake_coin, using: StakeCoinForMember
      end
    end
  end