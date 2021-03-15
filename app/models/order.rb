class Order < ActiveRecord::Base
  extend Enumerize

  enumerize :bid, in: Currency.enumerize
  enumerize :ask, in: Currency.enumerize
  enumerize :currency, in: Market.enumerize, scope: true
  enumerize :state, in: {:wait => 100, :done => 200, :cancel => 0}, scope: true

  ORD_TYPES = %w(market limit stop_loss stop_limit)
  enumerize :ord_type, in: ORD_TYPES, scope: true

  SOURCES = %w(Web APIv2 debug Kraken Binance)
  enumerize :source, in: SOURCES, scope: true

  after_commit :trigger
  before_validation :fix_number_precision, on: :create

  validates_presence_of :ord_type, :volume, :origin_volume, :locked, :origin_locked
  validates_numericality_of :origin_volume, :greater_than => 0

  validates_numericality_of :price, greater_than: 0, allow_nil: false,
                            if: "ord_type == 'limit'"
  validate :market_order_validations, if: "ord_type == 'market'"
  validate :minimum_trade_value, if: "ord_type == 'limit'"

  WAIT = 'wait'
  DONE = 'done'
  CANCEL = 'cancel'

  ATTRIBUTES = %w(id at market kind price state state_text volume origin_volume)

  belongs_to :member
  has_one :liquidity_status
  attr_accessor :total

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :position, -> { group("price").pluck(:price, 'sum(volume)') }
  scope :best_price, ->(currency) { where(ord_type: 'limit').active.with_currency(currency).matching_rule.position }

  def funds_used
    origin_locked - locked
  end

  def fee(trade)
    type = id == trade.maker ? 'maker' : 'taker'
    Fee.calculate(member.trade_volume, type)
  end

  def include_liquidity_fee liquidity_fee, trade
    fee(trade) + liquidity_fee
  end

  def config
    @config ||= Market.find(currency)
  end

  # def coin_holder_discount(fee)
  #   discount_percentage = HolderDiscount.calculate(member.coin_hold)
  #   CustomLogger.debug("Holder Discount - #{fee * discount_percentage / 100}")
  #   fee * discount_percentage / 100
  # end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, *ATTRIBUTES)
    end
    member.trigger('order', json)
  end

  def strike(trade, liquidity_fee=0.0, cross_order=false)
    raise "Cannot strike on cancelled or done order. id: #{id}, state: #{state}" unless state == Order::WAIT
    fee = liquidity_fee.zero? ? fee(trade) : include_liquidity_fee(liquidity_fee, trade)
    real_sub, add = get_account_changes trade
    CustomLogger.debug("Strike Fee - #{fee}")
    # real_fee      = (add * fee / 100) - coin_holder_discount(add * fee / 100)
    real_fee      = (add * fee / 100)
    real_add      = add - real_fee
    hold_account.unlock_and_sub_funds \
        real_sub, locked: real_sub,
        reason: (cross_order ? Account::CROSS_STRIKE_SUB : Account::STRIKE_SUB), ref: trade

    expect_account.plus_funds \
        real_add, fee: real_fee,
        reason: (cross_order ? Account::CROSS_STRIKE_ADD : Account::STRIKE_ADD), ref: trade

    self.volume         -= trade.volume
    self.locked         -= real_sub
    self.funds_received += add
    self.trades_count   += 1

    if volume.zero?
      self.state = Order::DONE

      # unlock not used funds
      hold_account.unlock_funds locked,
                                reason: Account::ORDER_FULLFILLED, ref: trade unless locked.zero?
    elsif ord_type == 'market' && locked.zero?
      # partially filled market order has run out its locked fund
      self.state = Order::CANCEL
    end

    self.save!
    currency = expect_account.currency
    CustomLogger.debug("Real Fee #{real_fee}")
    if member.referred?
      CustomLogger.debug("Going to try referral Commission")
      trade.try_referral_commission(real_fee, self,currency)
    else
      CustomLogger.debug("Straight to admin")
      trade.send_fee_to_admin(real_fee, currency)
    end unless real_fee.zero?
  end

  def self.check_eligibility(order_id, source)
    order = self.where(id: order_id).first
    return if order.blank?
    order.check_eligibility(source)
  end

  def kind
    type.underscore[-3, 3]
  end

  def self.head(currency)
    active.with_currency(currency.downcase).matching_rule.first
  end

  def at
    created_at.to_i
  end

  def display_currency
    config.name rescue '--'
  end

  def market
    currency
  end

  def to_matching_attributes
    { id: id,
      market: market,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      stop_price: stop_price,
      trigger_cond: trigger_cond,
      source: source,
      locked: locked,
      timestamp: created_at.to_i }
  end

  def fix_number_precision
    self.price = config.fix_number_precision(:bid, price.to_d) if price

    if volume
      self.volume = config.fix_number_precision(:ask, volume.to_d)
      self.origin_volume = origin_volume.present? ? config.fix_number_precision(:ask, origin_volume.to_d) : volume
    end
  end

  def source_binance?
    source == 'Binance'
  end

  def source_our_exchange?
    %w(Web APIv2).include? source
  end

  def check_eligibility(source)
    case source
      when 'Binance'
        # status = (!source_binance? && source_our_exchange?)
        status = (!source_binance? && source_our_exchange? && liquidity_enabled?)
      else
        Rails.logger.error "ERROR: Order source not found, Unable to place liquidity order"
    end
    if ENV['PLACE_LIQUIDITY_ORDERS'] != 'true'
      status = false
    end
    status ||= false
  end

  def liquidity_enabled?
    ENV['LIQUIDITY_MARKETS'].present? && eval(ENV['LIQUIDITY_MARKETS'])[currency].present?
  end

  private

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end

  def minimum_trade_value
    min_trade = config.min_trade || 0.0001
    errors.add(:total, "should be higher than #{min_trade.to_s}x") if (price * origin_volume < min_trade)
  end

  FUSE = '0.9'.to_d
  def estimate_required_funds(price_levels)
    required_funds = Account::ZERO
    expected_volume = volume
    return required_funds unless volume

    start_from, _ = price_levels.first
    filled_at     = start_from

    until expected_volume.zero? || price_levels.empty?
      level_price, level_volume = price_levels.shift
      filled_at = level_price

      v = [expected_volume, level_volume].min
      required_funds += yield level_price, v
      expected_volume -= v
    end

    raise "Market is not deep enough" unless expected_volume.zero?
    raise "Volume too large" if (filled_at-start_from).abs/start_from > FUSE

    required_funds
  end

end
