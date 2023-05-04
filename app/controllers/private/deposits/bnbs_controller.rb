module Private
  module Deposits
    class BnbsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end