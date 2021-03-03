class StakingDuration < ActiveRecord::Base
	has_many :staking_locked_durations
	has_many :stakings, through: :staking_locked_durations
  before_save :currency_case_changed
	validates :currency,:duration_days,:estimate_apy, presence: true
  validate :avoid_duplicate
  validate :check_flexible_duration

  def currency_case_changed
    self.currency = self.currency.to_s.upcase  
  end

  def avoid_duplicate
  	duration = StakingDuration.where.not(id: self.id).where("lower(currency) = (?) && duration_days = ?",self.currency.to_s.downcase,self.duration_days).last
  	if duration.present?
  		errors.add("currency", "with duration #{self.duration_days} is already used.")
  		errors.add("duration_days", "with currency #{self.currency} is already used.")
  	end
  end

  def check_flexible_duration
    if self.flexible.present?
      unless self.duration_days == 1
        errors.add("duration_days","is not greater than 1 days on flexible staking")
      end
    else
      unless self.duration_days > 6
        errors.add("duration_days","is not less than 7 days on locked staking")
      end
    end
  end

	def view_locked
		flexible ? "Flexible" : "Locked"
	end
end
