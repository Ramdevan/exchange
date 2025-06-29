class Currency < ActiveYamlBase
  include International
  include ActiveHash::Associations

  field :visible, default: true
  attr :name

  TAGS_REQUIRED = [:xrp, :xmr]
  DEPENDENT_NODES = [:eth, :bnb]

  self.singleton_class.send :alias_method, :all_with_invisible, :all
  def self.all
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|memo, i| memo[i.code.to_sym] = i.id; memo}
  end

  def self.codes
    @keys ||= all.map &:code
  end

  def self.get_dependent_coins(node = 'eth')
    coins ||= where(dependant_node: node, visible: true).map(&:code)
  end

  def self.crypto_coin_codes
    coins ||= where(coin: true).map(&:code)
  end

  def self.ids
    @ids ||= all.map &:id
  end

  def self.assets(code)
    find_by_code(code)[:assets]
  end

  def precision
    self[:precision]
  end

  def api
    raise unless coin?
    CoinRPC[code]
  end

  def fiat?
    not coin?
  end

  def balance_cache_key
    "axios:hotwallet:#{code}:balance"
  end

  def balance
    Rails.cache.read(balance_cache_key) || 0
  end

  def decimal_digit
    self.try(:default_decimal_digit) || (fiat? ? 2 : 4)
  end

  def refresh_balance
    Rails.cache.write(balance_cache_key, api.safe_getbalance) if coin?
  end

  def blockchain_url(txid)
    raise unless coin?
    blockchain.gsub('#{txid}', txid.to_s)
  end

  def address_url(address)
    raise unless coin?
    self[:address_url].try :gsub, '#{address}', address
  end

  def quick_withdraw_max
    @quick_withdraw_max ||= BigDecimal.new self[:quick_withdraw_max].to_s
  end

  def is_erc20?
    erc20_contract_address.present? ? true : false
  end

  def as_json(options = {})
    {
      key: key,
      code: code,
      coin: coin,
      blockchain: blockchain
    }
  end

  def summary
    locked = Account.locked_sum(code)
    balance = Account.balance_sum(code)
    sum = locked + balance

    coinable = self.coin?
    hot = coinable ? self.balance : nil

    {
      name: self.code.upcase,
      sum: sum,
      balance: balance,
      locked: locked,
      coinable: coinable,
      hot: hot
    }
  end

  def has_destination_tag?
    !!self[:has_destination_tag]
  end

  def self.all_fee_details
    all_coins = []
    Currency.all.each do |currency|
      next unless currency.coin?
      withdraw = WithdrawChannel.find_by_currency(currency.code)
      all_coins << {name: "#{currency.display_name} (#{currency.code.upcase})",
                    fee_val: withdraw.fee,
                    min_val: withdraw.min_withdraw
      }
    end
    return all_coins
  end
  
end
