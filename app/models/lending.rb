class Lending < ActiveRecord::Base
	belongs_to :lending_type
	has_many :lending_auto_transfers
	has_many :lending_subscriptions

	scope :today, -> { where("published_on >= ? && published_on <= ?", Date.today.beginning_of_day, Date.today.end_of_day) }
  scope :before_today, -> { where("published_on >= ?", Date.today.beginning_of_day) }

	after_create :update_date

	def locked_durations
		LendingDuration.where("currency = ?", currency)
	end

	def first_duration
		locked_durations.first
	end

	def self.flexible
		lending_types(LendingType.flexible.id)
	end

	def self.locked
		lending_types(LendingType.locked.id)
	end

	def self.activities
		lending_types(LendingType.activities.id)
	end

	def self.lending_types(type_id)
		includes(:lending_type).where(lending_type_id: type_id)
	end

	def interest_per_thousand
  	((1000*today_apy)/100)
  end

  def locked_interest_per_thousand(duration)
  	((1*duration.interest_rate)/100)
  end

  def auto_tansfer(member)
  	member.lending_auto_transfers.where(currency: currency).last
  end

  def set_account(member)
  	member.accounts.find_by(currency: currency.downcase)
  end

  def available_amount(member)
  	account = set_account(member)
  	"#{account.balance} #{currency}"
  end

  def amount(member)
  	set_account(member).amount
  end

  def locked(member)
    member.lending_subscriptions.not_completed.where(lending_id: id).count
  end

  def unlock_auto_tansfer(member)
  	fs = lending_subscriptions.where(member_id: member.id, is_auto_transfer: true).last
  	account = fs.set_account
  	account.unlock_funds fs.amount
  end

  def duration_percent(duration)
  	duration.interest_rate
  end

  def asset_redeem_date
		Date.today + duration_days.to_i.days
	end

	def lending_type_name
		lending_type.name
	end

	def interest_per_lot
  	((1*interest_rate)/100)
  end

  private

  def update_date
  	return unless lending_type_id == LendingType.activities.id

  	update_column(:name, "#{currency} #{duration_days}D (#{interest_rate}%)")
  end
end
