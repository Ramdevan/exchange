class MarketDetail < ActiveRecord::Base
	serialize :bid, JSON
	serialize :ask, JSON

  def self.enumerize
    all.inject({}) {|hash, i| hash[i.market_id.to_sym] = i.code; hash }
  end

  def self.to_hash
    return @markets_hash if @markets_hash

    @markets_hash = {}
    all.each {|m| @markets_hash[m.market_id] = m.unit_info }
    @markets_hash
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

    pair[:id] = self.market_id
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
    Trade.latest_price(market_id)
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
    market_id
  end

  def ask_currency
    CurrencyDetail.find_by_code(ask["currency"])
  end

  def bid_currency
    CurrencyDetail.find_by_code(bid["currency"])
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
    find_by_id('ethbtc') || first
  end

  def self.market_select
    all_list = all.map {|market| [ market.name, market.market_id ] }
    all_list.unshift(['All Pairs', ''])
  end

  private

  def global
    @global || Global[self.market_id]
  end
end
