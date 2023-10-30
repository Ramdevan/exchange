module Private
  module Withdraws
    class TmdsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
