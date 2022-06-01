module APIv2
    module Entities
      class StakeCoinForMember < Base
        expose :id
        expose :currency, documentation: "Name of the currency."
        expose :duration, documentation: "Number of days, in case of locked staking."
        expose :is_flexible, documentation: "Boolean denotes if the staking plan is flexible or locked."
        expose :is_active, documentation: "Boolean denotes if the staking plan is active."
        expose :current_variable_apy, using: VariableApy
      end
    end
  end
