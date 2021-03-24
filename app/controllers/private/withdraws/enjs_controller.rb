module Private
  module Withdraws
    class EnjsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
  