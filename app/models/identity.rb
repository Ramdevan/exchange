class Identity < ActiveRecord::Base
  # auth_key :email
  attr_accessor :old_password, :country, :phone_number, :first_name, :last_name

  MAX_LOGIN_ATTEMPTS = 5

  validates :email, presence: true, uniqueness: true, email: true
  validates :password, presence: true, length: { minimum: 6, maximum: 64 }
  validates :password_confirmation, presence: true, length: { minimum: 6, maximum: 64 }
  validates_presence_of :first_name, :last_name, :phone_number, if: :member_data_blank?
  validate :valid_phone_number_for_country, if: :member_data_blank?

  has_secure_password

  before_validation :sanitize

  def increment_retry_count
    self.retry_count = (retry_count || 0) + 1
  end

  def too_many_failed_login_attempts
    retry_count.present? && retry_count >= MAX_LOGIN_ATTEMPTS
  end

  def member
    Member.where(email: email).first
  end

  private

  def valid_phone_number_for_country
    self.phone_number = Phonelib.parse(self.phone_number).sanitized
    errors.add(:phone_number, :invalid) if Phonelib.invalid_for_country?(self.phone_number, self.country)
  end

  def sanitize
    self.email.try(:downcase!)
  end

  def member_data_blank?
    return true unless member
    member.first_name.blank? || member.last_name.blank? || member.phone_number.blank? || member.country_code.blank?
  end
end
