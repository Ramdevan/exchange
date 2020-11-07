module APIv2
  module Entities
    class Transaction < Base
      expose :id, documentation: "Unique deposit id."
      expose :currency
      expose :amount, format_with: :decimal
      expose :txid
      expose :aasm_state, as: :state
      expose :type, format_with: :transaction_type
      expose :created_at, :updated_at, :done_at, format_with: :iso8601
      expose :blockchain_url
      expose :fee

      private

      def transaction_type type
        type.split('s::').first
      end
    end
  end
end