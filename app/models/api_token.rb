class APIToken < ActiveRecord::Base
  acts_as_paranoid


  belongs_to :member
  belongs_to :oauth_access_token, class_name: 'Doorkeeper::AccessToken', dependent: :destroy

  serialize :trusted_ip_list

  validates_presence_of :access_key, :secret_key

  before_validation :generate_keys, on: :create

  scope :user_requested,  -> { where('oauth_access_token_id IS NULL') }
  scope :oauth_requested, -> { where('oauth_access_token_id IS NOT NULL') }

  def self.from_oauth_token(token)
    return nil unless token && token.token.present?
    access_key, secret_key = token.token.split(':')
    find_by_access_key access_key
  end

  def to_oauth_token
    [access_key, secret_key].join(':')
  end

  def expired?
    expire_at && expire_at < Time.now
  end

  def in_scopes?(ary)
    return true if ary.blank?
    return true if self[:scopes] == 'all'
    (ary & scopes).present?
  end

  def allow_ip?(ip)
    trusted_ip_list.blank? || trusted_ip_list.include?(ip)
  end

  def ip_whitelist=(list)
    self.trusted_ip_list = list.split(/,\s*/)
  end

  def ip_whitelist
    trusted_ip_list.try(:join, ',')
  end

  def scopes
    self[:scopes] ? self[:scopes].split(/\s+/) : []
  end

  def valid_pay_keys? token, tonce
    valid_token!(token, tonce) && valid_tonce!(tonce) ? true : false
  end

  private

  def generate_keys
    begin
      self.access_key = APIv2::Auth::Utils.generate_access_key
    end while APIToken.where(access_key: access_key).any?

    begin
      self.secret_key = APIv2::Auth::Utils.generate_secret_key
    end while APIToken.where(secret_key: secret_key).any?
  end

  def valid_token! token, tonce
    payload = "#{access_key}|#{member.sn}|#{tonce}"
    if token != APIv2::Auth::Utils.pay_hmac_signature(secret_key, payload)
      Rails.logger.warn "Pay auth failed: signature doesn't match. token: #{token} tonce: #{tonce} payload: #{payload}"
      return false
    end
    return true
  end

  def valid_tonce! tonce
    key = "pay:#{access_key}:tonce:#{tonce}"
    if APIv2::Auth::Utils.cache.read(key)
      Rails.logger.warn "Pay auth failed: used tonce. token: #{access_key} tonce: #{tonce}"
      return false
    end
    APIv2::Auth::Utils.cache.write key, tonce, 61 # forget after 61 seconds

    now = Time.now.to_i
    if tonce < now-30 || tonce > now+30 # within 30 seconds
      Rails.logger.warn "Pay auth failed: invalid tonce. token: #{access_key} tonce: #{tonce} current timestamp: #{now}"
      return false
    end
    return true
  end

end
