class PaymentTransaction < ActiveRecord::Base
  extend Enumerize

  include AASM
  include AASM::Locking
  include Currencible

  STATE = [:unconfirm, :confirming, :confirmed]
  enumerize :aasm_state, in: STATE, scope: true

  validates_presence_of :txid

  has_one :deposit
  belongs_to :payment_address, foreign_key: 'address', primary_key: 'address'

  after_update :sync_update

  aasm :whiny_transitions => false do
    state :unconfirm, initial: true
    state :confirming, after_commit: :deposit_accept
    state :confirmed, after_commit: :deposit_accept

    event :check do |e|
      before :refresh_confirmations

      transitions :from => [:unconfirm, :confirming], :to => :confirming, :guard => :min_confirm?
      transitions :from => [:unconfirm, :confirming, :confirmed], :to => :confirmed, :guard => :max_confirm?
    end
  end

  def min_confirm?
    deposit.min_confirm?(confirmations)
  end

  def max_confirm?
    deposit.max_confirm?(confirmations)
  end

  def refresh_confirmations
    raw = CoinRPC[deposit.currency].gettransaction(txid)
    self.confirmations = if deposit.currency_obj.is_erc20?
                           CoinRPC[deposit.currency].eth_blockNumber.to_i(16) - raw[:blockNumber].to_i(16)
                         elsif deposit.currency == 'xmr'
                           CoinRPC[deposit.currency].get_last_block_header.to_i - raw[:height].to_i
                         elsif deposit.currency == 'xrp'
                           CoinRPC[deposit.currency].calculate_confirmations raw
                         else
                           raw[:confirmations]
                         end
    save!
  end

  def deposit_accept
    if deposit.may_accept?
      deposit.accept! 
    end
  end

  def payment_address
    PaymentAddress.where(address: self.address, currency: self.currency).first
  end

  def account
    payment_address = PaymentAddress.where(address: self.address, currency: self.currency).first
    payment_address.account
  end

  def member
    account.member
  end

  private

  def sync_update
    if self.confirmations_changed?
      ::Pusher["private-#{deposit.member.sn}"].trigger_async('deposits', { type: 'update', id: self.deposit.id, attributes: {confirmations: self.confirmations}})
    end
  end
end
