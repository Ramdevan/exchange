module Deposits
  module Bankable
    extend ActiveSupport::Concern

    included do
      validates :fund_extra, :fund_uid, :amount, presence: true
      delegate :accounts, to: :channel
    end

    def as_json(options = {})
      super(options).merge({
                             display_type: display_type
                           })
    end

  end
end
