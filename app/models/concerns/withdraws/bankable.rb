module Withdraws
  module Bankable
    extend ActiveSupport::Concern

    def set_fee
      self.fee = WithdrawChannel.find_by(currency: currency_obj.code).fee.to_d
    end

    included do
      validates_presence_of :fund_extra

      delegate :name, to: :member, prefix: true

      alias_attribute :remark, :id
    end

    def as_json(options = {})
      super(options).merge({
                             display_type: display_type
                           })
    end

  end
end
