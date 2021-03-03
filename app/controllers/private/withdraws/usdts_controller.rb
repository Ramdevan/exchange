module Private
  module Withdraws
    class UsdtsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
