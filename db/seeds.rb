ADMIN_EMAIL = 'admin@citioption.com'
BINANCE_EMAIL = 'binance@citioption.com'
PASSWORD = '20d52bee'

admin_identity = Identity.find_or_create_by(email: ADMIN_EMAIL)
admin_identity.password = admin_identity.password_confirmation = PASSWORD
admin_identity.is_active = true
admin_identity.save!

admin_member = Member.find_or_create_by(email: ADMIN_EMAIL)
admin_member.authentications.build(provider: 'identity', uid: admin_identity.id)
admin_member.save!

user_identity = Identity.find_or_create_by(email: BINANCE_EMAIL)
user_identity.password = user_identity.password_confirmation = PASSWORD
user_identity.is_active = true
user_identity.save!

user_member = Member.find_or_create_by(email: BINANCE_EMAIL)
user_member.authentications.build(provider: 'identity', uid: user_identity.id)
user_member.save!

##### SET DEFAULT EFERRAL COMMISSIONS #####
ReferralCommission.create(min: 1, max: 100, fee_percent: 5)
ReferralCommission.create(min: 101, max: 1000, fee_percent: 10)
ReferralCommission.create(min: 1001, max: 100000, fee_percent: 15)

##### SET DEFAULT FEE #####
Fee.create(min: 0.0, max: 1000.0, maker: 0.1, taker: 0.1)
Fee.create(min: 1000.01, max: 10000.00, maker: 0.09, taker: 0.095)
Fee.create(min: 10000.01, max: 100000.00, maker: 0.08, taker: 0.09)
Fee.create(min: 100000.01, max: 1000000.00, maker: 0.075, taker: 0.08)

#Lending Types
flexible = LendingType.find_or_create_by(name: LendingType::FLEXIBLE)
locked = LendingType.find_or_create_by(name: LendingType::LOCKED)
activity = LendingType.find_or_create_by(name: LendingType::ACTIVITIES)

# Staking
# Locked Staking
[[15,21.49],[30,4.69],[60,5.21],[90,6.79]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "ETH",duration_days: i[0])
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::LOCKED_STAKING,currency: "ETH")
	staking.update_attributes(minimum_locked_amount: 10,maximum_locked_amount: 1000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end

[[15,32.79],[30,18.34],[60,22.49],[90,31.49]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "LTC",duration_days: i[0])
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::LOCKED_STAKING,currency: "LTC")
	staking.update_attributes(minimum_locked_amount: 10,maximum_locked_amount: 1000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end


[[15,22.79],[30,7.69],[60,12.34],[90,17.49]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "BCHABC",duration_days: i[0])
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::LOCKED_STAKING,currency: "BCHABC")
	staking.update_attributes(minimum_locked_amount: 100,maximum_locked_amount: 10000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end

[[30,10.18],[60,15.27],[90,24.79]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "DASH",duration_days: i[0])
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::LOCKED_STAKING,currency: "DASH")
	staking.update_attributes(minimum_locked_amount: 100,maximum_locked_amount: 10000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end

[[30,9.49],[60,14.79],[90,16.79]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "XRP",duration_days: i[0])
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::LOCKED_STAKING,currency: "XRP")
	staking.update_attributes(minimum_locked_amount: 100,maximum_locked_amount: 10000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end

# Defi Staking
[[1,7.49]].each do |i|
	duration = StakingDuration.find_or_create_by(currency: "BTC",duration_days: i[0],flexible: true)
	duration.update_attributes(estimate_apy: i[1])
	staking = Staking.find_or_create_by(staking_type: Staking::DEFI_STAKING,currency: "BTC")
	staking.update_attributes(minimum_locked_amount: 100,maximum_locked_amount: 10000)
	staking.staking_locked_durations.find_or_create_by(staking_duration_id: duration.try(:id))
end