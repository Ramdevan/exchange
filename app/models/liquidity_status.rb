class LiquidityStatus < ActiveRecord::Base

  extend Enumerize

  enumerize :state, in: ['NEW', 'PARTIALLY_FILLED', 'FILLED', 'CANCELED', 'PENDING_CANCEL', 'REJECTED', 'EXPIRED'], scope: true

  scope :pending,  -> { where('state IN (?)', ['NEW', 'PARTIALLY_FILLED']).order(liquid_id: :asc) }

  belongs_to :order
  has_many :liquidity_histories

end
