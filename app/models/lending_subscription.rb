class LendingSubscription < ActiveRecord::Base
  belongs_to :member
  belongs_to :lending
  belongs_to :lending_duration
  has_one :lending_redeem

  scope :yesterday, -> { where("subscription_date = ?", (Date.today - 1.day).to_date) }
  scope :end_subscriptions, -> {where("end_date >= ? && end_date <= ?", (Date.today - 1.day).beginning_of_day, (Date.today - 1.day).end_of_day)}
  scope :not_auto_transfer, -> {where(is_auto_transfer: false)}
  scope :not_completed, -> {where(is_completed: false)}

  after_create :lock_funds

  def self.flexibles
  	joins(:lending).where('lendings.lending_type_id = ?', LendingType.flexible.id)
  end

  def self.locked
  	joins(:lending).where('lendings.lending_type_id = ?', LendingType.locked.id)
  end

  def self.activities
  	joins(:lending).where('lendings.lending_type_id = ?', LendingType.activities.id)
  end

  def set_account
  	@account = member.get_account(lending.currency.downcase)
  end

  def today_interest
  	lending.today_apy
  end

  def unlock_funds
  	set_account
  	@account.unlock_funds amount
  end

  def currency
  	lending.currency
  end

  def value_date
  	case type
  	when I18n.t('private.history.subscription.flexible')
  		(sub_date + 1.day)
  	else
  		end_date.to_date
  	end
  end

  def sub_date
  	subscription_date || start_date.to_date
  end

  def type
  	lending.lending_type_name
  end

  def cummulative_interest
  	days = (Date.today - sub_date.to_date).to_i
  	interest_amount * days
  end

  def first_day_interest
  	((amount*today_interest)/100)
  end

  def update_flexible_redeem(status, type)
  	build_lending_redeem(redeem_type: type, redeem_date: Date.today, status: status)
  	self.save!
  	if status
  		update(interest_amount: first_day_interest)
  		unlock_funds
  		@account.plus_funds(interest_amount)
      update(is_completed: true)
  	else
  		update(interest_amount: cummulative_interest)
  	end
  end

  def total_interest
  	days = (value_date.to_date - sub_date.to_date).to_i
  	interest_rate = lending_duration.interest_rate
  	per_day_interest = ((amount*interest_rate)/100)
  	(per_day_interest * days)
  end

  def activity_total_interest
  	days = (value_date.to_date - sub_date.to_date).to_i
  	interest_rate = activity_lending.interest_rate
  	per_day_interest = ((amount*interest_rate)/100)
  	(per_day_interest * days)
  end

  private

  def lock_funds
  	set_account
  	@account.lock_funds amount
  end
end
