module Private
  module Deposits
    class BusdsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end