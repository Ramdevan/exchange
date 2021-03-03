module APIv2
  module Entities
    class FundSource < Base
      expose :id
      expose :currency
      expose :extra
      expose :uid
      expose :bank_code
      expose :created_at, format_with: :iso8601
      expose :destination_tag
      expose :label
      expose :is_default
    end
  end
end
