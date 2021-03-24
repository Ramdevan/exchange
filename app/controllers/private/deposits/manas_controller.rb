module Private
    module Deposits
      class ManasController < ::Private::Deposits::BaseController
        include ::Deposits::CtrlCoinable
      end
    end
  end
  