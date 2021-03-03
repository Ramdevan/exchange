class LiquidityHistory < ActiveRecord::Base

  serialize :detail, Hash

  belongs_to :liquidity_status

end
