module Private
  module Deposits
    class BcashesController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
