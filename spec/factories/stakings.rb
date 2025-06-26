FactoryBot.define do
  factory :staking do
    staking_type {"MyString"}
    currency {"MyString"}
    estimate_apy {1.5}
    flexible_lock {false}
    duration {1}
    minimum_locked_amount {1.5}
  end
end
