module Worker

  class DepositCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      channel_key = payload[:channel_key]
      txid = payload[:txid]

      channel = DepositChannel.find_by_key(channel_key)

      case channel.currency_obj.code
        when 'eth'
          raw  = get_raw_eth channel, txid
          raw.symbolize_keys!
          deposit_eth!(channel, txid, 1, raw)
        when 'usdt', 'usdc', 'citiusd','mana','enj'
          raw = get_raw_eth channel, txid
          raw.symbolize_keys!
          deposit_erc!(channel, txid, 1, raw)
        else
          raw  = get_raw channel, txid
          raw[:details].each_with_index do |detail, i|
            detail.symbolize_keys!
            deposit!(channel, txid, i, raw, detail)
          end
      end
    end

    def deposit_eth!(channel, txid, txout, raw)
      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: raw[:to]).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{raw[:to]}, amount: #{raw[:value].to_i(16) / 1e18}"
          return
        end
        Rails.logger.info "RAW DATA -- RAW-#{raw}, txid--#{txid}, txout-#{txout}"
        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first
        Rails.logger.info "Creating PaymentTransaction -- txid--#{txid}, txout-#{txout}"
        confirmations = CoinRPC[channel.currency_obj.code].eth_blockNumber.to_i(16) - raw[:blockNumber].to_i(16)
        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: raw[:to],
        amount: (raw[:value].to_i(16) / 1e18).to_d,
        confirmations: confirmations,
        receive_at: Time.now.to_datetime,
        currency: channel.currency

        deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations

        deposit.submit!
        deposit.accept!
      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{raw.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def deposit_erc!(channel, txid, txout, raw)
      ActiveRecord::Base.transaction do

        txn_receipt = CoinRPC[channel.currency_obj.code].get_txn_receipt txid

        unless PaymentAddress.where(currency: channel.currency_obj.id, address: CoinRPC[channel.currency_obj.code].to_address(txn_receipt)).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{raw[:to]}, amount: #{raw[:value].to_i(16) / 1e10}"
          return
        end

        Rails.logger.info "RAW DATA -- RAW-#{raw}, txnReceipt--#{txn_receipt}, txid--#{txid}, txout-#{txout}"
        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first

        Rails.logger.info "Creating PaymentTransaction -- txid--#{txid}, txout-#{txout}"
        confirmations = CoinRPC[channel.currency_obj.code].eth_blockNumber.to_i(16) - raw[:blockNumber].to_i(16)

        txn_receipt.fetch(:logs).map do |log|

          next if log.fetch('topics').blank? # || log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER
          next if txn_receipt.fetch(:to) != CoinRPC[channel.currency_obj.code].get_contract_address
          payment_address = CoinRPC[channel.currency_obj.code].normalize_address('0x' + log.fetch('topics').last[-40..-1])
          next if payment_address.blank? || PaymentAddress.where(currency: channel.currency_obj.id, address: payment_address).blank?

          tx = PaymentTransaction::Normal.create! \
          txid: txid,
          txout: txout,
          address: payment_address,
          amount: CoinRPC[channel.currency_obj.code].convert_from_base_unit(log.fetch('data').hex),
          confirmations: confirmations,
          receive_at: Time.now.to_datetime,
          currency: channel.currency

          deposit = channel.kls.create! \
          payment_transaction_id: tx.id,
          txid: tx.txid,
          txout: tx.txout,
          amount: tx.amount,
          member: tx.member,
          account: tx.account,
          currency: tx.currency,
          confirmations: tx.confirmations

          deposit.submit!
          deposit.accept!

        end
      end
    rescue
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{raw.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def deposit!(channel, txid, txout, raw, detail)
      return unless (detail[:account] == "payment" || detail[:category] == "receive")
      address = CoinRPC[channel.currency_obj.code].to_legacy_address(detail[:address])

      ActiveRecord::Base.transaction do
        unless PaymentAddress.where(currency: channel.currency_obj.id, address: address).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{address}, amount: #{detail[:amount]}"
          return
        end

        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first

        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: address,
        amount: detail[:amount].to_s.to_d,
        confirmations: raw[:confirmations],
        receive_at: Time.at(raw[:timereceived] || raw[:time]).to_datetime,
        currency: channel.currency

        deposit = channel.kls.create! \
        payment_transaction_id: tx.id,
        txid: tx.txid,
        txout: tx.txout,
        amount: tx.amount,
        member: tx.member,
        account: tx.account,
        currency: tx.currency,
        confirmations: tx.confirmations

        deposit.submit!
      end
    rescue => e
      ExceptionNotifier.notify_exception(e)
      Rails.logger.error "Failed to deposit: #{$!}"
      Rails.logger.error "txid: #{txid}, txout: #{txout}, detail: #{detail.inspect}"
      Rails.logger.error $!.backtrace.join("\n")
    end

    def get_raw(channel, txid)
      channel.currency_obj.api.gettransaction(txid)
    end

    def get_raw_eth(channel, txid)
      CoinRPC[channel.currency_obj.code].eth_getTransactionByHash(txid)
    end

  end
end