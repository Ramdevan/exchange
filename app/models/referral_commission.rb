class ReferralCommission < ActiveRecord::Base

  validates :max, presence: true
  validates :min, presence: true
  validates :fee_percent, presence: true
  validate :min_cannot_be_greater_than_max
  validate :current_min_cannot_be_less_than_previous_max, if: :do_validate?

	def self.calculate_commission(referral_count)
		referal_counts = ReferralCommission.all
    fee = BigDecimal.new(0)
		referal_counts.each do |count|
			if (count.min..count.max).include?(referral_count)  
				fee = count.fee_percent
		    break
			end
		end
		fee
  end
  
  def do_validate?
    self != ReferralCommission.first
  end

  def prev
    ReferralCommission.where("id < ?", id).last
  end

  def min_cannot_be_greater_than_max
    return if [min,max,fee_percent].include?(nil)
    errors.add(:min, "can't be greater than or equal to max") if min >= max
  end

  def current_min_cannot_be_less_than_previous_max
    return if [min,max,fee_percent].include?(nil)
    if self.id.nil?
      errors.add(:min, "can't be less than or equal to the previous max") if ReferralCommission.count > 0 && self.min <= ReferralCommission.last.max
    else
      errors.add(:min, "can't be less than or equal to the previous max") if self.min <= self.prev.max
    end
  end
end
