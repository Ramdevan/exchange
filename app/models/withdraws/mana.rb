module Withdraws
    class Mana < ::Withdraw
      include ::AasmAbsolutely
      include ::Withdraws::Coinable
      include ::FundSourceable
    end
  end
  