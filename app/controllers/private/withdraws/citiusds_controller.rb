module Private
  module Withdraws
    class CitiusdsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
