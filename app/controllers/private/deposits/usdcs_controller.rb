module Private
  module Deposits
    class UsdcsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
