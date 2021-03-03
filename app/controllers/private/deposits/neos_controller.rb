module Private
    module Deposits
        class NeosController < ::Private::Deposits::BaseController
            include ::Deposits::CtrlCoinable
        end
    end
end
  