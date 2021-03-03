require 'net/http'
require 'uri'
require 'json'

class CoinRPC
  class XRP < BTC

    def initialize(currency)
      @currency = currency
      @local_uri = URI.parse(currency.local_rpc)
      @uri = URI.parse(currency.rpc)
    end

    def handle_sign(name, *args)
      post_body = { 'method' => name, 'params' => args, 'id' => 'jsonrpc' }.to_json
      resp = JSON.parse( http_post_request_sign(post_body) )
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def http_post_request_sign(post_body)
      http    = Net::HTTP.new(@local_uri.host, @local_uri.port)
      request = Net::HTTP::Post.new(@local_uri.request_uri)
      request.basic_auth @local_uri.user, @local_uri.password
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      ExceptionNotifier.notify_exception(e)
      raise ConnectionRefusedError
    end

    def getnewaddress
      ["#{get_account_address}?dt=#{generate_destination_tag}", get_account_secret]
    end

    def mergeaddress address, destination_tag
      "#{address}?dt=#{destination_tag}"
    end

    def validateaddress address
      /\Ar[0-9a-zA-Z]{25,35}(:?\?dt=[0-9]\d*)?\z/.match(address).present? ? {isvalid: true} : {isvalid: false}
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
      tx[:DestinationTag] || destination_tag_from(tx[:Destination])
    end

    def latest_block_number
      Rails.cache.fetch :latest_ripple_ledger, expires_in: 5.seconds do
        result = handle :ledger, { "ledger_index": 'validated' }
        result[:ledger_index].to_i
      end
    end

    def fetch_transactions ledger_index
      result = handle :ledger, {"ledger_index": (ledger_index || 'validated'),
                                "transactions": true, "expand": true}
      result[:ledger]['transactions']
    end

    def listtransactions
      all_transactions = account_tx({"account": get_account_address})
      all_transactions[:transactions].each{ |transaction|
        tx = transaction["tx"].symbolize_keys!

        destination_tag = destination_tag_from_transaction(tx)
        address = mergeaddress tx[:Destination], destination_tag

        next if PaymentTransaction::Normal.where(txid: tx[:hash], currency: @currency.code).first
        next unless PaymentAddress.where(address: address, currency: @currency.code).first
        Rails.logger.info "***** Deposit for ripple - #{tx.inspect} ***** "
        AMQPQueue.enqueue :deposit_coin, {txid: tx[:hash], channel_key: @currency.key}
      }
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      puts "***** #{e.message} ***** "
      puts e.backtrace.inspect
    end

    def gettransaction txid
      handle :tx, {"transaction": txid}
    end

    def sendtoaddress from, to, amount
      tx_blob = sign_transaction(from, to, amount)
      result = handle :submit , tx_blob
      error_message = {
        message: result.fetch(:engine_result_message),
        status: result.fetch(:engine_result)
      }
      if result[:engine_result].to_s == 'tesSUCCESS' && result[:status].to_s == 'success'
        result.fetch(:tx_json).fetch('hash')
      else
        raise DepositError, "XRP withdrawal from #{from.fetch(:address)} to #{to.fetch(:address)} failed. Message: #{error_message}."
      end
    end

    def sign_transaction(from, to, amount)
      account_address = normalize_address(from.fetch(:address))
      destination_address = normalize_address(to.fetch(:address))
      destination_tag = destination_tag_from(to.fetch(:address))
      fee = calculate_current_fee
      amount_without_fee = convert_to_base_unit(amount) - fee.to_i

      params = {
        secret: from.fetch(:secret),
        tx_json: {
          Account:            account_address,
          Amount:             amount_without_fee.to_s,
          Fee:                fee,
          Destination:        destination_address,
          DestinationTag:     destination_tag,
          TransactionType:    'Payment',
          LastLedgerSequence: latest_block_number + 4
        },
        fee_mult_max: 0,
        fee_mult_div: 0
      }

      result = handle_sign :sign, params
      if result[:status].to_s == 'success'
        { tx_blob: result[:tx_blob] }
      else
        raise RuntimeError, "XRP sign transaction from #{account_address} to #{destination_address} failed: #{result}."
      end
    end

    # Returns fee in drops that is enough to process transaction in current ledger
    def calculate_current_fee
      result = handle :fee
      result[:drops]['open_ledger_fee']
    end

    def convert_to_base_unit(value)
      value = value.to_d * 1_000_000
      unless (value % 1).zero?
        raise Account::AccountError, "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " +
                                     "#{value.to_d} - #{value.to_d} must be equal to zero."
      end
      value.to_i
    end

    def convert_from_base_unit value
      (value.to_f / 1_000_000).to_d
    end

    def getbalance
      result = handle :account_info, {'account': get_account_address}
      balance = result[:account_data]['Balance']
      convert_from_base_unit balance
    end

    def calculate_confirmations(tx, ledger_index = nil)
      ledger_index ||= tx.fetch(:ledger_index)
      latest_block_number - ledger_index
    end

    def get_account_address
      @currency[:assets]['accounts'].first['address']
    end

    def get_account_secret
      @currency[:assets]['accounts'].first['secret']
    end

    private

    def generate_destination_tag
      begin
        # Reserve destination 1 for system purpose
        tag = SecureRandom.random_number(10**9) + 2
      end while PaymentAddress.where(currency: :xrp).where('address LIKE ?', "%dt=#{tag}").any?
      tag
    end

  end
end
