class Member < ActiveRecord::Base
  acts_as_taggable
  acts_as_reader

  has_many :orders
  has_many :accounts
  has_many :payment_addresses, through: :accounts
  has_many :withdraws
  has_many :fund_sources
  has_many :deposits
  has_many :api_tokens
  has_one  :mobile_api_token, -> {where api_type: :mobile}, class_name: 'APIToken'
  has_many :two_factors
  has_many :tickets, foreign_key: 'author_id'
  has_many :comments, foreign_key: 'author_id'
  has_many :signup_histories

  has_one :id_document

  has_many :authentications, dependent: :destroy

  belongs_to :referred_by, class_name: 'Member'
  has_many :referred_users, class_name: 'Member', foreign_key: :referred_by_id
  has_many :flexible_subscriptions, dependent: :destroy
  has_many :locked_subscriptions, dependent: :destroy
  has_many :activity_subscriptions, dependent: :destroy
  has_many :staking_locked_subscriptions, dependent: :destroy
  has_many :flexible_auto_tansfers, dependent: :destroy
  has_many :lending_auto_transfer, dependent: :destroy
  has_many :lending_subscriptions, dependent: :destroy
  has_many :lending_auto_transfers, dependent: :destroy

  scope :enabled, -> { where(disabled: false) }
  scope :referrals, -> (id) { where(referred_by: id) }

  delegate :activated?, to: :two_factors, prefix: true, allow_nil: true
  delegate :name,       to: :id_document, allow_nil: true
  delegate :first_name, to: :id_document, allow_nil: true
  delegate :last_name,  to: :id_document, allow_nil: true
  delegate :verified?,  to: :id_document, prefix: true, allow_nil: true

  before_validation :sanitize, :generate_sn

  validates :sn, presence: true
  validates :email, email: true, uniqueness: true, allow_nil: true
  validates :referral_code, uniqueness: true, allow_nil: true

  before_create :set_referral_code
  before_create :build_default_id_document
  after_create  :touch_accounts
  after_update :resend_activation
  after_update :sync_update

  attr_accessor :sms_2fa_activated, :app_2fa_activated, :two_factor_needed, :document_verification, :sms_check_activated

  class << self
    def from_auth(auth_hash,referral_code = nil)
      locate_auth(auth_hash) || locate_email(auth_hash) || create_from_auth(auth_hash,referral_code)
    end

    def current
      Thread.current[:user]
    end

    def current=(user)
      Thread.current[:user] = user
    end

    def admins
      Figaro.env.admin.split(',')
    end

    def search(field: nil, term: nil)
      result = case field
               when 'email'
                 where('members.email LIKE ?', "%#{term}%")
               when 'phone_number'
                 where('members.phone_number LIKE ?', "%#{term}%")
               when 'name'
                 joins(:id_document).where('id_documents.name LIKE ?', "%#{term}%")
               when 'wallet_address'
                 members = joins(:fund_sources).where('fund_sources.uid' => term)
                 if members.empty?
                  members = joins(:payment_addresses).where('payment_addresses.address' => term)
                 end
                 members
               else
                 all
               end

      result.order(:id).reverse_order
    end

    private

    def locate_auth(auth_hash)
      Authentication.locate(auth_hash).try(:member)
    end

    def locate_email(auth_hash)
      return nil if auth_hash['info']['email'].blank?
      member = find_by_email(auth_hash['info']['email'])
      return nil unless member
      member.add_auth(auth_hash)
      member
    end

    def create_from_auth(auth_hash, options)
      member = create(email: auth_hash['info']['email'], country_code: options[:country], phone_number: options[:phone_number], activated: false)
      member.add_auth(auth_hash)
      update_document(member, auth_hash, options)
      set_referral(member, options[:referral_code]) if options[:referral_code].present?
      member.send_activation if auth_hash['provider'] == 'identity'
      member
    end

    def update_document member, auth_hash, options
      id_document = member.id_document || member.create_id_document
      if id_document
        id_document.first_name = (options[:first_name] || auth_hash['info']['first_name'])
        id_document.last_name = (options[:last_name] || auth_hash['info']['last_name'])
        id_document.save(validate: false)
      end
    end

    def set_referral member, referral_code
      referrer = Member.find_by_referral_code(referral_code)
      member.update_attributes(referred_by: referrer) if referrer
    end
  end

  def limit_deposits(count)
    deposits = []
    Currency.all.each do |c|
      deposits.concat(Deposit.where(currency: c.code, member_id: id).order('id DESC').limit(count))
    end

    deposits
  end

  def limit_withdraws(count)
    withdraws = []
    Currency.all.each do |c|
      withdraws.concat(Withdraw.where(currency: c.code, member_id: id).order('id DESC').limit(count))
    end

    withdraws
  end

  def create_auth_for_identity(identity)
    self.authentications.create(provider: 'identity', uid: identity.id)
  end

  def trades
    Trade.where('bid_member_id = ? OR ask_member_id = ?', id, id)
  end

  def active!
    update activated: true
  end

  def update_password(password)
    identity.update password: password, password_confirmation: password
    send_password_changed_notification
  end

  def admin?
    @is_admin ||= self.class.admins.include?(self.email)
  end

  def add_auth(auth_hash)
    authentications.build_auth(auth_hash).save
  end

  def trigger(event, data)
    AMQPQueue.enqueue(:pusher_member, {member_id: id, event: event, data: data})
  end

  def notify(event, data)
    ::Pusher["private-#{sn}"].trigger_async event, data
  end

  def to_s
    "#{name || email} - #{sn}"
  end

  def display_name
    name || email
  end

  def short_name
    display_name.split(' ').map(&:first).join('')
  end

  def gravatar
    "//gravatar.com/avatar/" + Digest::MD5.hexdigest(email.strip.downcase) + "?d=retro"
  end

  def initial?
    name? and !name.empty?
  end

  def get_account(currency)
    account = accounts.with_currency(currency.to_sym).first

    if account.nil?
      touch_accounts
      account = accounts.with_currency(currency.to_sym).first
    end

    account
  end
  alias :ac :get_account

  def touch_accounts
    less = Currency.codes - self.accounts.map(&:currency).map(&:to_sym)
    less.each do |code|
      self.accounts.create(currency: code, balance: 0, locked: 0)
    end
  end

  def gen_addresses
    accounts.each do |account|
      next unless account.currency_obj.coin?

      if account.payment_addresses.blank?
        account.payment_addresses.create(currency: account.currency)
      else
        address = account.payment_addresses.last
        address.gen_address if address.address.blank?
      end
    end
  end

  def identity
    authentication = authentications.find_by(provider: 'identity')
    authentication ? Identity.find(authentication.uid) : nil
  end

  def auth(name)
    authentications.where(provider: name).first
  end

  def auth_with?(name)
    auth(name).present?
  end

  def remove_auth(name)
    identity.destroy if name == 'identity'
    auth(name).destroy
  end

  def send_activation
    Token::Activation.create(member: self)
  end

  def send_password_changed_notification
    MemberMailer.reset_password_done(self.id).deliver!

    if sms_two_factor.activated?
      sms_message = I18n.t('sms.password_changed', name: (self.name || self.email))
      AMQPQueue.enqueue(:sms_notification, phone: phone_number, message: sms_message)
    end
  end

  def unread_comments
    ticket_ids = self.tickets.open.collect(&:id)
    if ticket_ids.any?
      Comment.where(ticket_id: [ticket_ids]).where("author_id <> ?", self.id).unread_by(self).to_a
    else
      []
    end
  end

  def app_two_factor
    two_factors.by_type(:app)
  end

  def sms_two_factor
    two_factors.by_type(:sms)
  end

  def as_json(options = {})
    super(options).merge({
      "name" => self.name,
      "app_activated" => self.app_two_factor.activated?,
      "sms_activated" => self.sms_two_factor.activated?,
      "memo" => self.id
    })
  end

  def set_referral_code
    self.referral_code = SecureRandom.hex(6)
  end

  def touch_referral_code
    self.update(referral_code: SecureRandom.hex(6)) if referral_code.blank?
    loop do
      self.referral_code = SecureRandom.hex(6)
      break unless self.class.exists?(referral_code: referral_code)
      self.save
    end
  end

  def complete_referral!
    update(referral_completed_at: Time.zone.now)
    referred_by.increment_referral_count
  end

  def increment_referral_count
    increment!(:referral_count)
  end

  def referred?
    referred_by_id != nil
  end

  def valid_referral?
    referral_completed_at != nil
  end

  def get_total_balance(conversion_unit)
    total = 0.0
    accounts.each do |account|
      next unless account.currency
      balance = get_balance(account, conversion_unit)
      total += balance
    end
    return total
  end

  def get_balance(account, conversion_unit)
    balance = 0.0
    if account.currency == conversion_unit
      balance = (account.balance + account.locked)
    elsif market = Market.where(base_unit: account.currency, quote_unit: conversion_unit).first
      price = market.latest_price
      balance = (account.balance + account.locked) * price if price > 0
    elsif market = Market.where(base_unit: conversion_unit, quote_unit: account.currency).first
      price = market.latest_price
      balance = (account.balance + account.locked) / price if price > 0
    else
      base_market = Market.find_by_base_unit(account.currency) || Market.find_by_quote_unit(account.currency)
      return balance unless base_market

      if next_market = Market.where(base_unit: base_market[:quote_unit], quote_unit: conversion_unit).first 
        balance = (account.balance + account.locked) * base_market.latest_price * next_market.latest_price
      elsif next_market = Market.where(base_unit: conversion_unit, quote_unit: base_market[:quote_unit]).first 
        balance = ((account.balance + account.locked) * base_market.latest_price) / next_market.latest_price
      elsif next_market = Market.where(base_unit: base_market[:quote_unit], quote_unit: conversion_unit).first 
        balance = ((account.balance + account.locked) / base_market.latest_price) * next_market.latest_price
      elsif next_market = Market.where(base_unit: conversion_unit, quote_unit: base_market[:base_unit]).first 
        balance = ((account.balance + account.locked) / base_market.latest_price ) / next_market.latest_price
      end
    end
    balance
  end


  def country_code_alpha
    Phonelib.parse(phone_number).country
  end

  def last_login_time
     login = Loginhistory.where(member_id: self.id)
     login.present? ? login.last.login_time : '2020-08-03 17:37:07'
  end

  private

  def sanitize
    self.email.try(:downcase!)
  end

  def generate_sn
    self.sn and return
    begin
      self.sn = "X#{ROTP::Base32.random_base32(8).upcase}SEA"
    end while Member.where(:sn => self.sn).any?
  end

  def build_default_id_document
    build_id_document
    true
  end

  def resend_activation
    self.send_activation if self.email_changed?
  end

  def sync_update
    ::Pusher["private-#{sn}"].trigger_async('members', { type: 'update', id: self.id, attributes: self.changes_attributes_as_json })
  end
end
