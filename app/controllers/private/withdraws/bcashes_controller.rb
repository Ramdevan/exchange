module Private::Withdraws
  class BcashesController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
