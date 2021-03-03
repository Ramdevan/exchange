class ExchangeCommission < ActiveRecord::Base

  validates_presence_of :commission_type, :percentage
  validates_numericality_of :percentage, greater_than_or_equal_to: 0.to_d

end