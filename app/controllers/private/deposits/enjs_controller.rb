module Private
  module Deposits
    class EnjsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
  