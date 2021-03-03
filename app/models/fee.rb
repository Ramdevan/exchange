class Fee < ActiveRecord::Base
  validates :max, presence: true
  validates :min, presence: true
  validates :taker, presence: true
  validates :maker, presence: true
  validate :min_cannot_be_greater_than_max
  validate :current_min_cannot_be_less_than_previous_max, if: :do_validate?

  def prev
    Fee.where("id < ?", id).last
  end

  def self.calculate(trade_volume,type)
		fees = Fee.all
		fee = BigDecimal.new(0)
		fees.each do |count|
			if (count.min..count.max).include?(trade_volume)
				fee = count.send(type)
				break
			end
		end
		fee
  end

  def do_validate?
    Fee.all.empty? ? false : (self != Fee.first)
  end

  def min_cannot_be_greater_than_max
    return if [min, max, taker, maker].include?(nil)
    errors.add(:min, "can't be greater than or equal to max") if min >= max
  end

  def current_min_cannot_be_less_than_previous_max
    return if [min, max, taker, maker].include?(nil)
    if self.id.nil?
      errors.add(:min, "can't be less than or equal to the previous max") if self.min <= Fee.last.max
    else
      errors.add(:min, "can't be less than or equal to the previous max") if self.min <= self.prev.max
    end
  end
end