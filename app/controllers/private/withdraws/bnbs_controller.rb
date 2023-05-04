module Private
  module Withdraws
    class BnbsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
