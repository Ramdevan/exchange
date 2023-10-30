module Private
  module Deposits
    class TmdsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end