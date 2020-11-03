module APIv2
  module Entities
    class Currency < Base
      expose :id
      expose :display_name, as: :name, documentation: "Name of the currency."
      expose :code, documentation: "Currency code."
      expose :precision, as: :decimals, documentation: "Number of decimal digits."
      expose :balance, format_with: :decimal, documentation: "Balance available in the wallet."
      expose :locked, format_with: :decimal, documentation: "Balance locked for trade or withdrawl."
      expose :trade_pairs, documentation: "If this currency is a base market if count is greater than 0."
      expose :fiat
    end
  end
end
