module Worker

  class DepositCoin

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      sleep 0.5 # nothing result without sleep by query gettransaction api

      channel_key = payload[:channel_key]
      txid = payload[:txid]

      channel = DepositChannel.find_by_key(channel_key)

      if payload[:type] == Withdraw::INTERNAL_TRANSFER
	       deposit_internal_transaction(channel, txid, 1)
      else
       case channel.currency_obj.code
        when 'eth', 'bnb'
          raw  = get_raw_eth channel, txid
          raw.symbolize_keys!
          deposit_eth!(channel, txid, 1, raw)
        when 'usdt'
          raw = get_raw_eth channel, txid
          raw.symbolize_keys!
          deposit_erc!(channel, txid, 1, raw)
        when 'xrp'
          raw = get_raw_xrp channel, txid
          raw.symbolize_keys!
          deposit_xrp!(channel, txid, 1, raw)  
        else
          raw  = get_raw channel, txid
          raw[:details].each_with_index do |detail, i|
            detail.symbolize_keys!
            deposit!(channel, txid, i, raw, detail)
          end
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

    def deposit_xrp!(channel, txid, txout, raw)
      ActiveRecord::Base.transaction do

        destination_tag = CoinRPC[channel.currency_obj.code].destination_tag_from_transaction(raw)
        address = CoinRPC[channel.currency_obj.code].mergeaddress raw[:Destination], destination_tag

        unless PaymentAddress.where(currency: channel.currency_obj.id, address: address).first
          Rails.logger.info "Deposit address not found, skip. txid: #{txid}, txout: #{txout}, address: #{raw[:Destination]}, amount: #{raw[:Amount].to_i(16) / 1e18}"
          return
        end

        unless (raw[:TransactionType].to_s == 'Payment' && raw[:meta]['TransactionResult'].to_s == 'tesSUCCESS' && String === raw[:Amount])
          Rails.logger.info "Invalid data found, skip. raw: #{raw}"
          return
        end

        Rails.logger.info "RAW DATA -- RAW-#{raw}, txid--#{txid}, txout-#{txout}"
        return if PaymentTransaction::Normal.where(txid: txid, txout: txout).first
        Rails.logger.info "Creating PaymentTransaction -- txid--#{txid}, txout-#{txout}"
        tx = PaymentTransaction::Normal.create! \
        txid: txid,
        txout: txout,
        address: address,
        amount: (raw[:Amount].to_i / 1_000_000).to_d,
        confirmations: CoinRPC[channel.currency_obj.code].calculate_confirmations(raw),
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

    def deposit_internal_transaction(channel, txid, txout)
      details = Withdraw.find_by_txid(txid)
      return unless details.present?
      destination_tag = details.fund_tag
      address = details.fund_tag.present? ? "#{details.fund_uid}?dt=#{details.fund_tag}" : details.fund_uid

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
        amount: details.amount,
        confirmations: 10,
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

    def get_raw(channel, txid)
      channel.currency_obj.api.gettransaction(txid)
    end

    def get_raw_eth(channel, txid)
      CoinRPC[channel.currency_obj.code].gettransaction(txid)
    end

    def get_raw_xrp(channel, txid)
      CoinRPC[channel.currency_obj.code].gettransaction(txid)
    end

  end
end
