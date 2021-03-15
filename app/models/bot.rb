class Bot < ActiveRecord::Base
  ZERO = '0.0'.to_d

  validates :market_id, :best_price, :best_buy, :best_sell, :min_price, :max_price, :best_vol, :min_vol, :max_vol, presence: true
  validates_numericality_of :best_price, :min_price, :max_price, :best_vol, :min_vol, :max_vol, greater_than: ZERO
  validates_uniqueness_of :market_id

  after_validation :validate_and_calculate

  def market
    Market.where(id: market_id).first
  end

  def market_name
    market.name
  end

  def self.restart_daemon
    # `bundle exec rake daemon:autobot:restart`
    system("bundle exec rake daemon:autobot:restart")
  end

  def self.kill_daemon
    `kill -9 $(pgrep -f 'autobot')`
  end

  private

  def validate_and_calculate
    return if errors.present?
    self.errors.add(:max_price, "should be greated than min price") if min_price >= max_price
    self.errors.add(:best_price, "should be between min and max price") unless best_price.between?(min_price, max_price)
    self.errors.add(:best_buy, "should be less than best price") if best_price <= best_buy
    self.errors.add(:best_sell, "should be greater than best price") if best_price >= best_sell
    self.errors.add(:best_buy, "should be greater than min price") if best_buy < min_price
    self.errors.add(:best_sell, "should be lesser than max price") if best_sell > max_price
    self.errors.add(:max_vol, "should be greated than min volume") if min_vol >= max_vol
    self.errors.add(:best_vol, "should be between min and max volume") unless best_vol.between?(min_vol, max_vol)
    self.errors.add(:base, "Order between seconds should be valid") if start_sec.present? && end_sec.present? && (start_sec > end_sec)
    self.errors.add(:base, "Trade between seconds should be valid") if start_sec_trade.present? && end_sec_trade.present? && (start_sec_trade > end_sec_trade)
  end
end
