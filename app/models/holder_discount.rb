class HolderDiscount < ActiveRecord::Base
  validates :max, presence: true
  validates :min, presence: true
  validates :percent, presence: true
  validate :min_cannot_be_greater_than_max
  validate :current_min_cannot_be_less_than_previous_max, if: :do_validate?

  def self.calculate(amount)
		discounts = HolderDiscount.all
		fee = BigDecimal.new(0)
		discounts.each do |count|
			if (count.min..count.max).include?(amount)
				fee = count.percent
				break
			end
		end
		fee
  end

  def do_validate?
    HolderDiscount.all.empty? ? false : (self != HolderDiscount.first)
  end

  def min_cannot_be_greater_than_max
    return if [min, max, percent].include?(nil)
    errors.add(:min, "can't be greater than or equal to max") if min >= max
  end

  def current_min_cannot_be_less_than_previous_max
    return if [min, max, percent].include?(nil)
    if self.id.nil?
      errors.add(:min, "can't be less than or equal to the previous max") if self.min <= HolderDiscount.last.max
    else
      errors.add(:min, "can't be less than or equal to the previous max") if self.min <= self.prev.max
    end
  end
end
