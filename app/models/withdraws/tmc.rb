module Withdraws
  class Tmc < ::Withdraw
    include ::AasmAbsolutely
    include ::Withdraws::Coinable
    include ::FundSourceable
  end
end