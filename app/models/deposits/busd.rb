module Deposits
  class Busd < ::Deposit
    include ::AasmAbsolutely
    include ::Deposits::Coinable

    validates_uniqueness_of :txout, scope: :txid
  end
end