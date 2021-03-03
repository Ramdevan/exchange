module APIv2
  module Entities
    class Withdraw < Base
      expose :id
      expose :currency do |withdraw|
        withdraw.currency.upcase
      end
      expose :sum, as: :total_amount
      expose :amount, as: :actual_amount
      expose :fee
      expose :txid
      expose :fund_uid, as: :address
      expose :state do |withdraw|
        case withdraw.aasm_state.to_sym
        when :canceled                            then :cancelled
        when :suspect                             then :suspected
        when :rejected, :accepted, :done, :failed, :processing, :submitting, :almost_done then withdraw.aasm_state
        else :submitted
        end
      end
      expose :created_at, :updated_at, :done_at, format_with: :iso8601
    end
  end
end