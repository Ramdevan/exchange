class Account < ActiveRecord::Base
  include Currencible

  FIX = :fix
  UNKNOWN = :unknown
  STRIKE_ADD = :strike_add
  STRIKE_SUB = :strike_sub
  STRIKE_FEE = :strike_fee
  STRIKE_UNLOCK = :strike_unlock
  ORDER_CANCEL = :order_cancel
  ORDER_SUBMIT = :order_submit
  ORDER_FULLFILLED = :order_fullfilled
  WITHDRAW_LOCK = :withdraw_lock
  WITHDRAW_UNLOCK = :withdraw_unlock
  DEPOSIT = :deposit
  WITHDRAW = :withdraw
  STAKING_LOCK = :staking_lock
  STAKING_UNLOCK = :staking_unlock
  TRADE_FEES = :trade_fees
  ZERO = 0.to_d
  REFERRAL_FEES = :referral_fees
  PAY_SUB = :pay_sub
  PAY_ADD = :pay_add
  PAY_COMMISSION = :pay_commission
  FLEXIBLE_LENDING = :flexible_lending
  LOCKED_LENDING = :locked_lending
  ACTIVITY_LENDING = :activity_lending
  LOCKED_STAKING = :locked_staking
  # When liquidity order is not placed due to some error, 
  #        still order has to be closed locally to maintain orderbook BUY/ASK depth level.
  #        so liquidity order & local order gets matched.
  CROSS_STRIKE_ADD = :cross_strike_add
  CROSS_STRIKE_SUB = :cross_strike_sub

  FUNS = {:unlock_funds => 1, :lock_funds => 2, :plus_funds => 3, :sub_funds => 4, :unlock_and_sub_funds => 5}
  DEFAULT_FIAT = 'usdt'

  belongs_to :member
  has_many :payment_addresses
  has_many :versions, class_name: "::AccountVersion"
  has_many :partial_trees

  # Suppose to use has_one here, but I want to store
  # relationship at account side. (Daniel)
  belongs_to :default_withdraw_fund_source, class_name: 'FundSource'

  validates :member_id, uniqueness: { scope: :currency }
  validates_numericality_of :balance, :locked, greater_than_or_equal_to: ZERO

  scope :enabled, -> { where("currency in (?)", Currency.ids) }

  after_commit :trigger, :sync_update

  def payment_address
    payment_addresses.last || payment_addresses.create(currency: self.currency)
  end

  def self.after(*names)
    names.each do |name|
      m = instance_method(name.to_s)
      define_method(name.to_s) do |*args, &block|
        m.bind(self).(*args, &block)
        yield(self, name.to_sym, *args)
        self
      end
    end
  end

  def self.currency_details(id)
    where(member_id: id).map do |acc|
      c = Currency.find_by_code(acc.currency)
      currency = {}
      currency[:id] = c.id
      currency[:display_name] = c.display_name
      currency[:code] = c.code
      currency[:precision] = c.precision
      currency[:locked] = acc.locked
      currency[:balance] = acc.balance_precision
      currency[:trade_pairs] = Market.where(quote_unit: c.code).count
      currency[:fiat_price] = (c.code == DEFAULT_FIAT) ? "1".to_d : Rails.cache.read("axios:#{c.code}#{DEFAULT_FIAT}:ticker")[:last] rescue Trade.latest_price("#{c.code}#{DEFAULT_FIAT}".to_sym)
      currency
    end
  end

  def plus_funds(amount, fee: ZERO, reason: nil, ref: nil)
    (amount <= ZERO or fee > amount) and raise AccountError, "cannot add funds (amount: #{amount})"
    change_balance_and_locked amount, 0
  end

  def sub_funds(amount, fee: ZERO, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.balance) and raise AccountError, "cannot subtract funds (amount: #{amount})"
    change_balance_and_locked -amount, 0
  end

  def lock_funds(amount, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.balance) and raise AccountError, "cannot lock funds (amount: #{amount})"
    change_balance_and_locked -amount, amount
  end

  def unlock_funds(amount, reason: nil, ref: nil)
    (amount <= ZERO or amount > self.locked) and raise AccountError, "cannot unlock funds (amount: #{amount})"
    change_balance_and_locked amount, -amount
  end

  def unlock_and_sub_funds(amount, locked: ZERO, fee: ZERO, reason: nil, ref: nil)
    raise AccountError, "cannot unlock and subtract funds (amount: #{amount})" if ((amount <= 0) or (amount > locked))
    raise LockedError, "invalid lock amount" unless locked
    raise LockedError, "invalid lock amount (amount: #{amount}, locked: #{locked}, self.locked: #{self.locked})" if ((locked <= 0) or (locked > self.locked))
    change_balance_and_locked locked-amount, -locked
  end

  after(*FUNS.keys) do |account, fun, changed, opts|
    begin
      opts ||= {}
      fee = opts[:fee] || ZERO
      reason = opts[:reason] || Account::UNKNOWN

      attributes = { fun: fun,
                     fee: fee,
                     reason: reason,
                     amount: account.amount,
                     currency: account.currency.to_sym,
                     member_id: account.member_id,
                     account_id: account.id }

      if opts[:ref] and opts[:ref].respond_to?(:id)
        ref_klass = opts[:ref].class
        attributes.merge! \
          modifiable_id: opts[:ref].id,
          modifiable_type: ref_klass.respond_to?(:base_class) ? ref_klass.base_class.name : ref_klass.name
      end

      locked, balance = compute_locked_and_balance(fun, changed, opts)
      attributes.merge! locked: locked, balance: balance

      AccountVersion.optimistically_lock_account_and_create!(account.balance, account.locked, attributes)
    rescue ActiveRecord::StaleObjectError
      ExceptionNotifier.notify_exception(ActiveRecord::StaleObjectError)
      Rails.logger.info "Stale account##{account.id} found when create associated account version, retry."
      account = Account.find(account.id)
      raise ActiveRecord::RecordInvalid, account unless account.valid?
      retry
    end
  end

  def self.compute_locked_and_balance(fun, amount, opts)
    raise AccountError, "invalid account operation" unless FUNS.keys.include?(fun)

    case fun
    when :sub_funds then [ZERO, ZERO - amount]
    when :plus_funds then [ZERO, amount]
    when :lock_funds then [amount, ZERO - amount]
    when :unlock_funds then [ZERO - amount, amount]
    when :unlock_and_sub_funds
      locked = ZERO - opts[:locked]
      balance = opts[:locked] - amount
      [locked, balance]
    else raise AccountError, "forbidden account operation"
    end
  end

  def amount
    self.balance + self.locked
  end

  def balance_precision
    c = Currency.find_by_code(self.currency)
    div = balance.to_d.to_s('F').split('.')
    div[1].present? ? "#{div[0]}.#{div[1][0..(c.precision-1)]}".to_d : "#{div[0]}".to_d
  end  

  def last_version
    versions.last
  end

  def examine
    expected = 0
    versions.find_each(batch_size: 100000) do |v|
      expected += v.amount_change
      return false if expected != v.amount
    end

    expected == self.amount
  end

  def trigger
    return unless member

    json = Jbuilder.encode do |json|
      json.(self, :balance, :locked, :currency)
    end
    member.trigger('account', json)
  end

  def change_balance_and_locked(delta_b, delta_l)
    self.balance += delta_b
    self.locked  += delta_l
    self.class.connection.execute "update accounts set balance = balance + #{delta_b}, locked = locked + #{delta_l} where id = #{id}"
    add_to_transaction # so after_commit will be triggered
    self
  end

  scope :locked_sum, -> (currency) { with_currency(currency).sum(:locked) }
  scope :balance_sum, -> (currency) { with_currency(currency).sum(:balance) }

  class AccountError < RuntimeError; end
  class LockedError < AccountError; end
  class BalanceError < AccountError; end

  def as_json(options = {})
    super(options).merge({
      # check if there is a useable address, but don't touch it to create the address now.
      "deposit_address" => payment_addresses.empty? ? "" : payment_address.deposit_address,
      "destination_tag" => payment_addresses.empty? ? "" : payment_address.destination_tag,
      "name_text" => currency_obj.name_text,
      "default_withdraw_fund_source" => default_withdraw_fund_source
    })
  end

  private

  def sync_update
    ::Pusher["private-#{member.sn}"].trigger_async('accounts', { type: 'update', id: self.id, attributes: {balance: balance, locked: locked} })
  end

end
