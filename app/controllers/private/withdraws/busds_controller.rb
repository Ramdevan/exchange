module Private
  module Withdraws
    class BusdsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
