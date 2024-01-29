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
	      if withdraw.txid == Withdraw::INTERNAL_TRANSFER
          currency = Currency.find_by_code(withdraw.currency)
          from_address = PaymentAddress.where(account_id: withdraw.account_id).pluck(:address).last
          address = from_address.split('?')
          from_address = address.first if address.size > 1
          txid = "#{withdraw.txid}_#{withdraw.currency}_#{from_address}_#{withdraw.fund_uid}_#{Time.now.to_i}"
          AMQPQueue.enqueue(:deposit_coin, txid: txid, channel_key: currency.key, type: Withdraw::INTERNAL_TRANSFER)
	      else
          currency = Currency.find_by_code(withdraw.currency)
          node = currency.dependant_node  
        case withdraw.currency

        when 'eth', 'bnb'
          from_address = Currency.find_by_code(withdraw.currency)[:assets]['accounts'].first['address']
          balance = Web3Currency.get_balance(withdraw.currency, from_address)
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          node == 'bnb' ? Web3Currency.unlockaccount(from_address) : CoinRPC[withdraw.currency].personal_unlockAccount(from_address, "", 15000)
          txid = CoinRPC[withdraw.currency].sendtoaddress(from_address, withdraw.fund_uid, withdraw.amount)
        when 'usdt', 'busd', 'tmd', 'tmc'
          from_address = Currency.find_by_code(withdraw.currency)[:assets]['accounts'].first['address']
          balance = Web3Currency.get_token_balance(withdraw.currency, from_address)
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          node == 'bnb' ? Web3Currency.unlockaccount(from_address) : CoinRPC[withdraw.currency].personal_unlockAccount(from_address, "", 15000)
          txid = CoinRPC[withdraw.currency].sendtoaddress(from_address, withdraw.fund_uid, withdraw.amount)
        when 'xrp'
          balance = CoinRPC[withdraw.currency].getbalance - 10 # 10 XRP is account's reserve balance
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          from_address = {address: CoinRPC[withdraw.currency].get_account_address,
                          secret: CoinRPC[withdraw.currency].get_account_secret}
          to_address = {address: CoinRPC[withdraw.currency].mergeaddress(withdraw.fund_uid, withdraw.fund_tag)}
          txid = CoinRPC[withdraw.currency].sendtoaddress(from_address, to_address, (withdraw.amount).to_i)  
        else
          balance = CoinRPC[withdraw.currency].getbalance.to_d
          raise Account::BalanceError, 'Insufficient coins' if balance < withdraw.sum
          txid = CoinRPC[withdraw.currency].sendtoaddress withdraw.fund_uid, withdraw.amount.to_f
        end
       end

        withdraw.whodunnit('Worker::WithdrawCoin') do
          unless txid.blank?
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
end
