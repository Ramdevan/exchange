module Worker
  class DepositCoinAddress

    def process(payload, metadata, delivery_info)
      payload.symbolize_keys!

      payment_address = PaymentAddress.find payload[:payment_address_id]
      return if payment_address.address.present?

      member = payment_address.account.member
      currency = payload[:currency]
      case currency
        when 'eth', 'usdt', 'bnb', 'busd', 'tmd'
          address  = CoinRPC[currency].find_or_initialize_address(member.id) # Uses same address for all dependent coins (ex: ETH, USDT)
        when 'xrp'
          address, secret = CoinRPC[currency].getnewaddress
          payment_address.secret = secret  
        else
          address  = CoinRPC[currency].getnewaddress("payment")
      end
      if payment_address.update address: address
        ::Pusher["private-#{member.sn}"].trigger_async('deposit_address', { type: 'create', attributes: payment_address.as_json})
      end
    end

  end
end
