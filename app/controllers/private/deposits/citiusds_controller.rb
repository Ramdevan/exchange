module Private
  module Deposits
    class CitiusdsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
