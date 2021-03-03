module Private
  module Deposits
    class DashesController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
