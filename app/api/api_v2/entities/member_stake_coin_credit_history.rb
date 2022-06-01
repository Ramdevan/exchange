module APIv2
    module Entities
      class MemberStakeCoinCreditHistory < Base
        expose :id
        expose :credit_amount, documentation: "Coins credited."
        expose :credit_percent, documentation: "Rate of interest at which interest is credited."
        expose :created_at, documentation: "Interest credited time."
      end
    end
  end