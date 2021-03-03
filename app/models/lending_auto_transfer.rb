class LendingAutoTransfer < ActiveRecord::Base
  belongs_to :member
  belongs_to :lending
end
