class Trade < ActiveRecord::Base
  extend ActiveHash::Associations::ActiveRecordExtensions
  ZERO = '0.0'.to_d
  CONVERSION_UNIT = ENV['CONVERSION_UNIT'] || 'btc'
  extend Enumerize
  enumerize :trend, in: {:up => 1, :down => 0}
  enumerize :currency, in: Market.enumerize, scope: true

  belongs_to :market, class_name: 'Market', foreign_key: 'currency'
  belongs_to :ask, class_name: 'OrderAsk', foreign_key: 'ask_id'
  belongs_to :bid, class_name: 'OrderBid', foreign_key: 'bid_id'

  belongs_to :ask_member, class_name: 'Member', foreign_key: 'ask_member_id'

  belongs_to :bid_member, class_name: 'Member', foreign_key: 'bid_member_id'

  validates_presence_of :price, :volume, :funds

  after_create :check_for_first_trade

  scope :h24, -> { where("created_at > ?", 24.hours.ago) }

  attr_accessor :side, :base_currency, :quote_currency

  alias_method :sn, :id

  class << self
    def latest_price(currency)
      with_currency(currency).order(:id).reverse_order
        .limit(1).first.try(:price) || "0.0".to_d
    end

    def filter(market, timestamp, from, to, limit, order)
      trades = with_currency(market).order(order)
      trades = trades.limit(limit) if limit.present?
      trades = trades.where('created_at <= ?', timestamp) if timestamp.present?
      trades = trades.where('id > ?', from) if from.present?
      trades = trades.where('id < ?', to) if to.present?
      trades
    end

    def for_member(currency, member, options={})
      trades = filter(currency, options[:time_to], options[:from], options[:to], options[:limit], options[:order]).where("ask_member_id = ? or bid_member_id = ?", member.id, member.id)
      trades.each do |trade|
        trade.side = trade.ask_member_id == member.id ? 'ask' : 'bid'
      end
    end

  end
  
  def trigger_notify
    ask.member.notify 'trade', for_notify('ask') if ask_id.present?
    bid.member.notify 'trade', for_notify('bid') if bid_id.present?
  end

  def for_notify(kind=nil)
    {
      id:     id,
      kind:   kind || side,
      at:     created_at.to_i,
      price:  price.to_s  || ZERO,
      volume: volume.to_s || ZERO,
      market: currency
    }
  end

  def for_global
    {
      tid:    id,
      type:   trend == 'down' ? 'sell' : 'buy',
      date:   created_at.to_i,
      price:  price.to_s || ZERO,
      amount: volume.to_s || ZERO
    }
  end

  def maker
    # Whichever the order's id lowest in a trade is considered as the maker
    # Adding compact for liquidity orders will also work
    [ask_id, bid_id].compact.min
  end

  def members
    [bid_member, ask_member]
  end

  def check_for_first_trade
    members.each do |member|
      member.complete_referral! if member && member.trades.count == 1 && member.referred?
    end
  end

  def try_referral_commission(fee, order, currency)
    order = bid.member == order.member ? bid : ask
    referrer = order.member.referred_by
    commission = ReferralCommission.calculate_commission(referrer.referral_count)
    total_fees = fee * commission/100
    admin_fee = fee - total_fees
    CustomLogger.debug("Total Fees #{total_fees}")
    CustomLogger.debug("Fees #{fee}")
    CustomLogger.debug("Admin Fees #{admin_fee}")
    if total_fees.to_f > 0
      referrer.accounts.find_by_currency(currency).lock!.plus_funds(total_fees, fee: ZERO, reason: Account::REFERRAL_FEES, ref: self)
      referrer.accounts.find_by_currency(currency).increment!(:referral_commissions, total_fees)
    end
    send_fee_to_admin(admin_fee, currency)  if admin_fee.to_f > 0
  end

  def send_fee_to_admin(fee, currency)
    CustomLogger.debug("Sending fee of #{fee} of currency #{currency} to admin")
    admin = Member.find_by_email(ENV['ADMIN'])
    admin.accounts.find_by_currency(currency).lock!.plus_funds(fee, fee: ZERO,reason: Account::TRADE_FEES, ref: self )
  end

  def self.conversion_unit_of_market_pair
    markets = Market.all
    market_pair = []
    markets_map = {}
    markets.each do |market|
      market_pair << market.id
      markets_map[market.id] =  {base_unit: market.base_unit, quote_unit: market.quote_unit}
    end
    markets_map.each do |key, value|
      conversion_available = false
      if market_pair.include?(key)
        if value[:quote_unit] == CONVERSION_UNIT
          markets_map[key][:operation] = 'multiply-funds'
          markets_map[key][:unit] = 1
          conversion_available = true
        elsif value[:base_unit] == CONVERSION_UNIT
          markets_map[key][:unit] = 1
          markets_map[key][:operation] = 'multiply-volume'
          conversion_available = true
        end
        market_pair.delete(key) if conversion_available
      end
    end

    market_pair.each do |market|
      get_cross_market_conversion(market, markets_map, CONVERSION_UNIT)
    end
    return markets_map
  end

  def self.get_cross_market_conversion(market, markets_map, conversion_unit)
    base_unit = markets_map[market][:base_unit]
    quote_unit = markets_map[market][:quote_unit]
    if markets_map[quote_unit+conversion_unit]
      markets_map[market][:operation] = 'multiply-funds'
      markets_map[market][:unit] = Market.find(quote_unit+conversion_unit).latest_price
    elsif markets_map[base_unit+conversion_unit]
      markets_map[market][:operation] = 'multiply-volume'
      markets_map[market][:unit] = Market.find(base_unit+conversion_unit).latest_price
    elsif conversion_unit != 'btc'
      markets_map = get_cross_market_conversion(market, markets_map, 'btc')
      if markets_map[quote_unit+'btc'] || markets_map[base_unit+'btc']
        markets_map[market][:unit] = markets_map[market][:unit] * Market.find('btc'+conversion_unit).latest_price
      end
    else
      Rails.logger.warn("Missing conversion logic for #{market}")
    end
    markets_map
  end

  def self.get_trading_volume(user_id, from=nil, to=nil)
    return unless user_id
    condition = "(ask_member_id=? OR bid_member_id=?)"
    args = [user_id, user_id]
    if from && to
      condition += " AND (DATE(created_at) >= ? AND DATE(created_at) <= ?)"
      args << from
      args << to
    end
    trading_volume = 0.0
    trades = Trade.where(condition, *args)
    markets_map = conversion_unit_of_market_pair
    trades.each do |trade|
      case markets_map[trade.currency][:operation]
      when 'multiply-funds'
        trading_volume +=  trade.funds * markets_map[trade.currency][:unit]
      when 'multiply-volume'
        trading_volume +=  trade.volume * markets_map[trade.currency][:unit]
      else
      end
    end
    return trading_volume
  end
end
