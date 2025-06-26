class FundSource < ActiveRecord::Base
  include Currencible

  attr_accessor :name
  attr_accessor :is_default

  acts_as_paranoid


  belongs_to :member

  before_validation :validate_destination_tag, on: :create

  validates_presence_of :uid, :extra, :member

  def label
    # if currency_obj.try :coin?
      "#{uid} (#{extra})"
    # else
    #   [I18n.t("banks.#{extra}"), "****#{uid[-4..-1]}"].join('#')
    # end
  end

  def as_json(options = {})
    super(options).merge({label: label})
  end

  def validate_destination_tag
    self.errors[:destination_tag] << "is required" if Currency::TAGS_REQUIRED.include?(self.currency.to_sym) && self.destination_tag.blank?
  end

end
