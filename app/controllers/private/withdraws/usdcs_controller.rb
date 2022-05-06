module Private
  module Withdraws
    class UsdcsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
