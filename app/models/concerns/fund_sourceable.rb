module FundSourceable
  extend ActiveSupport::Concern

  included do
    attr_accessor :fund_source
    before_validation :set_fund_source_attributes, on: :create
    validates :fund_source, presence: true, on: :create
  end

  def set_fund_source_attributes
    if fs = FundSource.find_by(id: fund_source)
      self.fund_extra = fs.extra
      self.fund_uid = fs.uid.strip
      self.fund_tag = fs.destination_tag.strip if fs.currency_obj.has_destination_tag?
      self.bank_code = fs.bank_code if fs.bank_code.present?
    end
  end
end
