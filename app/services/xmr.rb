require 'net/http'
require 'uri'
require 'json'

class CoinRPC
  class XMR < BTC
    #NOTE: Payment_id is also knows as destination_tag for XRP and XMR code convenience.

    def handle(name, args={})
      post_body = { 'method' => name, 'params' => args, "jsonrpc" => "2.0", "id" => "0"}.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def wallet_uri
      @uri = URI.parse(@currency.wallet_rpc)
    end

    def getnewaddress label=''
      "#{get_account_address}?dt=#{generate_payment_id}"
    end

    def get_account_address
      @currency[:assets]['accounts'].first['address']
    end

    def mergeaddress address, destination_tag
      "#{address}?dt=#{destination_tag}"
    end

    def normalize_address(address)
      address.gsub(/\?dt=\d*\Z/, '')
    end

    def to_address(address)
      normalize_address(address)
    end

    def destination_tag_from address
      address =~ /\?dt=(\d*)\Z/
      $1.to_i
    end

    def destination_tag_from_transaction tx
      tx[:payment_id] || destination_tag_from(tx[:payment_id])
    end

    def get_last_block_header
      result = handle :get_last_block_header
      result[:block_header]["height"]
    end

    def gettransaction txid
      wallet_uri
      post_body = { 'method' => :get_transfer_by_txid , 'params' => {'txid': txid}, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def getbalance
      wallet_uri
      result = handle :getbalance
      balance = convert_from_base_unit result[:balance]
      return balance
    end

    def sendtoaddress to, payment_id, value
      wallet_uri
      result = handle :transfer, { "destinations": [{ "amount": convert_to_base_unit(value), "address": to }], "get_tx_key": true }
      return result[:tx_key]
    end

    def convert_to_base_unit(value)
      value = value.to_d * 1e12
      unless (value % 1).zero?
        raise Account::AccountError, "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " +
                                     "#{value.to_d} - #{value.to_d} must be equal to zero."
      end
      value.to_i
    end

    def convert_from_base_unit value
      (value.to_i / 1e12).to_d
    end

    def validateaddress address
      xmr_mainnet_address_regex = /^4([0-9]|[A-B])(.){93}/
      {isvalid: true} # Uncomment this line and comment below for testnet validation
      #xmr_mainnet_address_regex.match(address) ? {isvalid: true} : {isvalid: false}
    end

    def listtransactions(count = nil)
      begin
        last_block = get_last_block_header
        wallet_uri
        count ||= 100
        from_block = last_block - count
  
        result = handle(:get_transfers, { "in" => true, "filter_by_height" => true, "min_height" => from_block })
        if result && result[:in]
          result[:in].each { |result_in|
            Rails.logger.info "***** Deposit succeeded - txid: #{result_in['txid']} *****" 
            postData = Net::HTTP.post_form(URI.parse("#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}/webhooks/xmr"), {'type' => 'transaction', 'hash' => result_in["txid"]})
          }
        end
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        logger.info "***** #{e.message} ***** "
        logger.info e.backtrace.inspect
        sleep 2
      end
    end

    private

    def generate_payment_id
      begin
        wallet_uri
        result = handle :make_integrated_address
        payment_id = result[:payment_id]
      end while PaymentAddress.where(currency: :xmr).where('address LIKE ?', "%dt=#{payment_id}").any?
      payment_id
    end

  end
end
