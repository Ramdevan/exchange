module Worker
  class WithdrawCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.processing?

        withdraw.whodunnit('Worker::WithdrawCoin') do
          withdraw.call_rpc
          withdraw.save!
        end
      end

      Withdraw.transaction do
        withdraw = Withdraw.lock.find payload[:id]

        return unless withdraw.almost_done?
        case withdraw.currency
        when 'eth'
          balance = EthereumBalance.get
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          from_address = Currency.find_by_code(withdraw.currency)[:assets]['accounts'].first['address']
          CoinRPC[withdraw.currency].personal_unlockAccount(from_address, "", 15000)
          txid = CoinRPC[withdraw.currency].eth_sendTransaction(from: from_address, to: withdraw.fund_uid, value: '0x' + ((withdraw.amount.to_f * 1e18).to_i.to_s(16)))
        when 'usdt'
          from_address = Currency.find_by_code(withdraw.currency)[:assets]['accounts'].first['address']
          CoinRPC[withdraw.currency].personal_unlockAccount(from_address, "", 15000)
          txid = CoinRPC[withdraw.currency].sendtoaddress(from_address, withdraw.fund_uid, withdraw.amount)
        else
          balance = CoinRPC[withdraw.currency].getbalance.to_d
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          txid = CoinRPC[withdraw.currency].sendtoaddress withdraw.fund_uid, withdraw.amount.to_f
        end

        withdraw.whodunnit('Worker::WithdrawCoin') do
          withdraw.update_columns(txid: txid, done_at: Time.current)
          # withdraw.succeed! will start another transaction, cause
          # Account after_commit callbacks not to fire
          withdraw.succeed
          withdraw.save!
        end
      end
    end

  end
end
