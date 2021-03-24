module Private
    module Withdraws
      class ManasController < ::Private::Withdraws::BaseController
        include ::Withdraws::Withdrawable
      end
    end
  end
  