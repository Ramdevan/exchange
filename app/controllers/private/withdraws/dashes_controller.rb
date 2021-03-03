module Private
  module Withdraws
    class DashesController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
