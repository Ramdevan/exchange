class LockedDuration < ActiveRecord::Base
	has_many :staking_locked_durations
	has_many :stakings, through: :staking_locked_durations
	has_one :locked_subscription

	scope :today, -> { where("published_on >= ? && published_on <= ?", Date.today.beginning_of_day, Date.today.end_of_day) }
end
