module Private
  module Deposits
    class TmcsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end