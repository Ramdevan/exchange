class LendingRedeem < ActiveRecord::Base
  belongs_to :lending_subscription
  scope :inprogress_standard, -> {where(redeem_type: I18n.t('redeem_lendings.standard'), status: false)}
  scope :yesterday, -> { where("redeem_date >= ? && redeem_date <= ?", (Date.today - 1.day).beginning_of_day, (Date.today - 1.day).end_of_day) }
end
