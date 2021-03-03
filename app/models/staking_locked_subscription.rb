class StakingLockedSubscription < ActiveRecord::Base
	belongs_to :member
	belongs_to :staking
	belongs_to :staking_locked_duration
	belongs_to :staking_duration
	validate :check_avaliable_balance
	after_create :set_locked_period, :update_account_detail
	LOCKED = "LOCKED"
	COMPLETED = "COMPLETED"
	CANCELLED = "CANCELLED"

	scope :locked_stakings, -> {joins(:staking).where("stakings.staking_type = ?", Staking::LOCKED_STAKING).where(status: StakingLockedSubscription::LOCKED)}
	scope :defi_stakings, -> {joins(:staking).where("stakings.staking_type = ?", Staking::DEFI_STAKING).where(status: StakingLockedSubscription::LOCKED)}

	def set_locked_period
		self.update_attributes(start_date: get_start_date,end_date: get_end_date ,status: StakingLockedSubscription::LOCKED,interest_percentage: self.try(:staking_duration).try(:estimate_apy).to_f)
	end

	def get_stake_date
		(self.created_at || Time.now)
	end

	def get_start_date
		((self.created_at || Time.now) + 1.day).beginning_of_day
	end

	def get_end_date(duration=nil)
		duration = duration || self.try(:staking_duration).try(:duration_days).to_i
		(get_start_date + duration.to_i.days - 1.minutes)
	end

	def update_account_detail
		if account.present?
			account.lock_funds self.try(:amount).to_f, reason: Account::LOCKED_STAKING
		end
	end

	def check_avaliable_balance
		if member.present?
			if account.present?
				unless account.try(:balance).to_f >= self.try(:amount).to_f
					errors.add("member","#{self.try(:staking).try(:currency)} account has insufficient balance")
				end
			else
				errors.add("member","#{self.try(:staking).try(:currency)} account is not found")
			end
		else
			errors.add("member","is cann't be blank!")
		end
	end

	def account
		if member.present?
			account = member.get_account(self.try(:staking).try(:currency).to_s.downcase)
		else
			account = nil
		end
		return account
	end

	def is_redeem_now
		Time.now > self.end_date
	end

	def early_redeem
		if account.present?
			account.unlock_funds amount.to_f
			update_attributes(status: StakingLockedSubscription::CANCELLED)
		end
	end

	def redeem_now
		if is_redeem_now.present?
  		staking_account = account
  		if staking_account.present?
  			interest_percentage = staking_duration.try(:estimate_apy).to_f
  			amount = self.amount.to_f
  			per_day_interest = ((amount * interest_percentage)/100)
  			interest_amount = staking_duration.try(:duration_days).to_f * per_day_interest
  			staking_account.unlock_funds amount
  			staking_account.plus_funds interest_amount
  			update_attributes(interest_amount: interest_amount,status: StakingLockedSubscription::COMPLETED)
  		end
  	end
	end

	def valid_redeem
		Time.now > self.start_date
	end
end
