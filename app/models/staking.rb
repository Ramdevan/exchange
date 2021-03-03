class Staking < ActiveRecord::Base
	LOCKED_STAKING = "LOCKED_STAKING"
	DEFI_STAKING = "DEFI_STAKING"
	has_many :staking_locked_durations, dependent: :destroy
	has_many :staking_durations
	has_many :staking_locked_subscriptions, dependent: :destroy

	scope :all_locked_stackings, -> {where(staking_type: Staking::LOCKED_STAKING)}
	scope :all_defi_stackings, -> {where(staking_type: Staking::DEFI_STAKING)}
	scope :locked_stackings, -> {all_locked_stackings.where(is_active: true)}
	scope :defi_stackings, -> {all_defi_stackings.where(is_active: true)}
	scope :today, -> { where("published_on >= ? && published_on <= ?", Date.today.beginning_of_day, Date.today.end_of_day) }

	validates :staking_type,:currency,:minimum_locked_amount,:maximum_locked_amount, presence: true
  validate :check_locked_amount

	accepts_nested_attributes_for :staking_locked_durations

	def check_locked_amount
		if minimum_locked_amount == 0
			errors.add(:minimum_locked_amount, "should be greater than zero")
		end
		unless minimum_locked_amount < maximum_locked_amount
      errors.add(
        :maximum_locked_amount,
        I18n.t(
          'staking.invalid_maximum_locked_amount',
          min_price: minimum_locked_amount,
          max_price: maximum_locked_amount
        )
      )
    end
	end

	def locked_staking?
		staking_type == Staking::LOCKED_STAKING
	end

	def defi_staking?
		staking_type == Staking::DEFI_STAKING
	end

	def option_for_locked_type (flexible)
		durations = staking_durations(flexible)
		durations.map{|m| [m.view_locked,m.flexible] }.uniq
	end

	def options_for_staking_durations(flexible=self.defi_staking?)
		staking_locked_durations.joins(:staking_duration).where("staking_durations.flexible = ?",flexible)
	end

	def current_locked_staking(member)
		staking_locked_subscriptions.where(member_id: member.try(:id)).locked_stakings.find_by(staking_id: self.id)
	end

	def status_view
		self.is_active ? "Active" : "Deactive"
	end

	def status_action
		self.is_active ? "deactive" : "active"
	end

	def any_present_locked
		if self.locked_staking?
			StakingLockedSubscription.locked_stakings.where("stakings.id = ?",self.id).last
		else
			StakingLockedSubscription.defi_stakings.where("stakings.id = ?",self.id).last
		end
	end

	def both_present_locked(member)
		StakingLockedSubscription.joins(:staking).where(status: StakingLockedSubscription::LOCKED).where(member_id: member.try(:id)).where("stakings.currency = ?",self.currency).last
	end

	def locked_durations
		StakingDuration.where("currency = ? && flexible = ?", currency, false)
	end

	def defi_durations
		StakingDuration.where("currency = ? && flexible = ?", currency, true)
	end

	def first_staking_duration(flexible)
		staking_durations(flexible).first
	end

	def staking_durations(flexible)
		flexible ? defi_durations : locked_durations
	end
end
