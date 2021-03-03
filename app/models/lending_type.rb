class LendingType < ActiveRecord::Base
	has_many :lendings
	validates_uniqueness_of :name

	FLEXIBLE = 'Flexible'
	LOCKED = 'Locked'
	ACTIVITIES = 'Activities'

	def self.flexible
		find_by(name: LendingType::FLEXIBLE)
	end

	def self.locked
		find_by(name: LendingType::LOCKED)
	end

	def self.activities
		find_by(name: LendingType::ACTIVITIES)
	end
end
