class MissingBlock < ActiveRecord::Base
	scope :get_blocks, -> { where(status: false) }
end
