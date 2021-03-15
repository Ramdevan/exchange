# People exchange commodities in markets. Each market focuses on certain
# commodity pair `{A, B}`. By convention, we call people exchange A for B
# *sellers* who submit *ask* orders, and people exchange B for A *buyers*
# who submit *bid* orders.
#
# ID of market is always in the form "#{B}#{A}". For example, in 'btccny'
# market, the commodity pair is `{btc, cny}`. Sellers sell out _btc_ for
# _cny_, buyers buy in _btc_ with _cny_. _btc_ is the `base_unit`, while
# _cny_ is the `quote_unit`.

class Market < ActiveYamlBase
  field :visible, default: true

  attr :current_price, :price_change, :base_currency, :base_decimals, :quote_currency, :quote_decimals, :name, :icon

  self.singleton_class.send :alias_method, :all_with_invisible, :all
  def self.all
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|hash, i| hash[i.id.to_sym] = i.code; hash }
  end

  def self.to_hash
    return @markets_hash if @markets_hash

    @markets_hash = {}
    all.each {|m| @markets_hash[m.id.to_sym] = m.unit_info }
    @markets_hash
  end

  def initialize(*args)
    super

    raise "missing base_unit or quote_unit: #{args}" unless base_unit.present? && quote_unit.present?
    @name = self[:name] || "#{base_unit}/#{quote_unit}".upcase
  end

  def self.stats
    all.map do |market|
      trading_pair = market.details
    end
  end

  def self.trading_pairs(currency)
    where(quote_unit: currency).map do |market|
      trading_pair = market.details
    end
  end

  def new_price_change(p1, p2)
    change = 0
    if p1
      change = 100*(p2-p1)/p1
    end
    change
  end

  def details
    pair = {}
    p1 = self.ticker[:open]
    p2 = self.ticker[:last]
    new_price = new_price_change(p1, p2)
    new_price = 0.0 if new_price.nan?
    base_currency = self.ask_currency
    quote_currency = self.bid_currency

    pair[:id] = self.id
    pair[:name] = self.name
    pair[:base_currency] = base_currency.display_name
    pair[:base_decimals] = base_currency.precision
    pair[:quote_currency] = quote_currency.display_name
    pair[:quote_decimals] = quote_currency.precision
    pair[:current_price] = self.latest_price
    pair[:price_change] = new_price.to_d
    pair[:base_unit] = self.base_unit
    pair[:quote_unit] = self.quote_unit
    pair[:icon] = "/icon-#{base_currency.code}.png"
    pair
  end

  def latest_price
    Trade.latest_price(id.to_sym)
  end

  # type is :ask or :bid
  def fix_number_precision(type, d)
    digits = send(type)['fixed']
    d.round digits, 2
  end

  # shortcut of global access
  def bids;   global.bids   end
  def asks;   global.asks   end
  def trades; global.trades end
  def ticker; global.ticker end

  def to_s
    id
  end

  def ask_currency
    Currency.find_by_code(ask["currency"])
  end

  def bid_currency
    Currency.find_by_code(bid["currency"])
  end

  def scope?(account_or_currency)
    code = if account_or_currency.is_a? Account
             account_or_currency.currency
           elsif account_or_currency.is_a? Currency
             account_or_currency.code
           else
             account_or_currency
           end

    base_unit == code || quote_unit == code
  end

  def unit_info
    {name: name, base_unit: base_unit, quote_unit: quote_unit}
  end

  def self.default_one
    find_by_id('btcusdt') || first
  end

  def self.select_options
    all.map { |market| ["#{market.name} (#{market.bid['fixed']} Decimals)", market.id] }
  end

  private

  def global
    @global || Global[self.id]
  end

end
