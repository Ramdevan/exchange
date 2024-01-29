module Private
  module Withdraws
    class TmcsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
