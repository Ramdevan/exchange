module APIv2
  module Entities
    class Market < Base
      expose :id, documentation: "Unique market id. It's always in the form of xxxyyy, where xxx is the base currency code, yyy is the quote currency code, e.g. 'btccny'. All available markets can be found at /api/v2/markets."
      expose :current_price, documentation: "Current price of the market pair."
      expose :price_change, documentation: "Last 24h value changes"
      expose :base_currency
      expose :base_decimals
      expose :quote_currency
      expose :quote_decimals
      expose :name
      expose :base_unit
      expose :quote_unit
      expose :icon
      expose :base_unit
      expose :quote_unit
    end
  end
end
