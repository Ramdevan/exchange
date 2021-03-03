module Private
    module Withdraws
        class NeosController < ::Private::Withdraws::BaseController
            include ::Withdraws::Withdrawable
        end
    end
end