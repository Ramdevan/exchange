ADMIN_EMAIL = 'admin@ioio.com'
BINANCE_EMAIL = 'binance@ioio.com'
PASSWORD = '20d52bee'

admin_identity = Identity.find_or_create_by(email: ADMIN_EMAIL)
admin_identity.password = admin_identity.password_confirmation = PASSWORD
admin_identity.first_name = 'Admin'
admin_identity.last_name = 'User'
admin_identity.country = 'IN'
admin_identity.phone_number = '9876543210'
admin_identity.is_active = true
admin_identity.save(validate: false)

admin_member = Member.find_or_create_by(email: ADMIN_EMAIL)
admin_member.authentications.build(provider: 'identity', uid: admin_identity.id)
admin_member.save(validate: false)

binance_identity = Identity.find_or_create_by(email: BINANCE_EMAIL)
binance_identity.password = binance_identity.password_confirmation = PASSWORD
binance_identity.first_name = 'Binance'
binance_identity.last_name = 'User'
binance_identity.country = 'IN'
binance_identity.phone_number = '9876543210'
binance_identity.is_active = true
binance_identity.save(validate: false)

binance_member = Member.find_or_create_by(email: BINANCE_EMAIL)
binance_member.authentications.build(provider: 'identity', uid: binance_identity.id)
binance_member.save(validate: false)


##### SET DEFAULT EFERRAL COMMISSIONS #####
ReferralCommission.create(min: 1, max: 100, fee_percent: 5)
ReferralCommission.create(min: 101, max: 1000, fee_percent: 10)
ReferralCommission.create(min: 1001, max: 100000, fee_percent: 15)

##### SET DEFAULT FEE #####
Fee.create(min: 0.0, max: 1000.0, maker: 0.1, taker: 0.1)
Fee.create(min: 1000.01, max: 10000.00, maker: 0.09, taker: 0.095)
Fee.create(min: 10000.01, max: 100000.00, maker: 0.08, taker: 0.09)
Fee.create(min: 100000.01, max: 1000000.00, maker: 0.075, taker: 0.08)