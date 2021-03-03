class StakingLockedDuration < ActiveRecord::Base
	belongs_to :staking_duration
	belongs_to :staking

	def view_duration
		self.try(:staking_duration).try(:flexible).present? ? "Flexible" :  self.try(:staking_duration).try(:duration_days)
	end

	def duration_days
		self.try(:staking_duration).try(:duration_days).to_i
	end
end
