class IdDocument < ActiveRecord::Base
  extend Enumerize
  include AASM
  include AASM::Locking

  has_one :id_document_file, class_name: 'Asset::IdDocumentFile', as: :attachable, :validate => false
  accepts_nested_attributes_for :id_document_file

  has_one :id_bill_file, class_name: 'Asset::IdBillFile', as: :attachable, :validate => false
  accepts_nested_attributes_for :id_bill_file

  #has_one :id_selfie_file, class_name: 'Asset::IdSelfieFile', as: :attachable
  #accepts_nested_attributes_for :id_selfie_file

  belongs_to :member

  has_many :kyc_comments
  
  validates_presence_of :id_document_file, :id_bill_file, :on => :update
  validates_presence_of :first_name, :last_name, :id_document_type, :id_document_number, :id_bill_type, allow_nil: true
  validates_uniqueness_of :member

  enumerize :id_document_type, in: {id_card: 0, passport: 1, drivers: 2, residence_permit: 3}
  enumerize :id_bill_type,     in: {utility_bill: 0}
  enumerize :source_of_funds,  in: {employment: 0, savings: 1, trading_profits: 2, inheritance: 3}
  enumerize :financial_instruments,  in: {crypto_currencies: 0, CFDs: 1, Margin_FX: 2, Equities: 3, Commodities: 4, Bonds: 5}

  alias_attribute :full_name, :name

  aasm do
    state :unverified, initial: true
    state :verifying
    state :verified, after_commit: :gen_addresses
    state :rejected

    event :submit do
      transitions from: [:unverified, :rejected], to: :verifying
      after do
        send_status_email
        send_sms
      end
    end

    event :approve do
      transitions from: [:rejected, :unverified, :verifying],  to: :verified
      after do
        send_status_email
        send_sms
      end
    end

    event :reject do
      transitions from: [:unverified, :verifying, :verified],  to: :rejected
      after do
        send_status_email
        send_sms
      end
    end
  end

  def bill_file_path
    "#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}#{id_bill_file.file.url}" if id_bill_file.present?
  end

  def document_file_path
    "#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}#{id_document_file.file.url}" if id_document_file.present?
  end

  #def selfie_file_path
  #  "#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}#{id_selfie_file.file.url}" if id_selfie_file.present?
  #end

  def name
    [first_name, last_name].join(' ')
  end

  def self.document_type(document) # For Sumsub
    if id_document_type.values.map(&:upcase).include? document
      "id_document_file"
    elsif id_bill_type.values.map(&:upcase).include? document
      "id_bill_file"
    #else
    #"id_selfie_file"
    end
  end

  def gen_addresses
    member.gen_addresses
  end

  def send_status_email
    MemberMailer.kyc_status(member.id).deliver
  end

  def send_sms
    return true if not member.sms_two_factor.activated?

    case aasm_state
    when 'verifying'
      sms_message = I18n.t('sms.kyc_submit', name: (member.name || member.email))
    when 'verified'
      sms_message = I18n.t('sms.kyc_approve', name: (member.name || member.email))
    when 'rejected'
      sms_message = I18n.t('sms.kyc_reject', name: (member.name || member.email))
    end

    return true unless defined?(sms_message)
    AMQPQueue.enqueue(:sms_notification, phone: member.phone_number, message: sms_message)
  end

end
