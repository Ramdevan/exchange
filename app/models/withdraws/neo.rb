module Withdraws
    class Neo < ::Withdraw
        include ::AasmAbsolutely
        include ::Withdraws::Coinable
        include ::FundSourceable
    end
end