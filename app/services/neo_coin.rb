require 'net/http'
require 'net/https'

class CoinRPC

  class NEO < self

    SUCCESS = '0x1'

    def handle(name, *args)
      post_body = {"jsonrpc" => "2.0", 'method' => name, 'params' => args, 'id' => '1'}.to_json
      resp = JSON.parse(http_post_request(post_body))
      raise JSONRPCError, resp['error'] if resp['error']
      result = resp['result']
      result.symbolize_keys! if result.is_a? Hash
      result
    end

    def http_post_request(post_body)
      http = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      ExceptionNotifier.notify_exception(e)
      raise ConnectionRefusedError
    end

    def latest_block_number
      Rails.cache.fetch :latest_neo_block_number, expires_in: 5.seconds do
        handle(:getwalletheight)
      end
    end

    def normalize_address(address)
      address.downcase
    end

    def safe_getbalance
      begin
        getbalance
      rescue
        'N/A'
      end
    end

    def getbalance
        handle(:getbalance, get_neo_asset_id)[:confirmed].to_d
    end

    # def get_userbalance address
    #   response = handle(:getaccountstate, address)
    #   total_balance = 0.0
    #   response[:balances].each do |balance|
    #     total_balance += balance["value"].to_f
    #   end

    #   total_balance
    # end

    def listtransactions(count = nil)
      latest_block = latest_block_number
      count ||= 10
      from_block = latest_block - count
      our_accounts = get_accounts.map{|acc| acc["address"]}

      (from_block..latest_block).each do |block_num|
        block_json = get_block_details(block_num)
        next if block_json.blank? || (block_json[:tx].count == 0)

        block_json[:tx].each do |block_txn|
          has_no_transactions = block_txn['vout'].count == 0
          next if has_no_transactions
          is_neo_asset = block_txn['vout'].first["asset"] == get_neo_asset_id
          is_our_address = our_accounts.include?(block_txn['vout'].first['address'])
          
          if is_neo_asset && is_our_address
            Net::HTTP.post_form(URI.parse("#{ENV['URL_SCHEMA']}://#{ENV['URL_HOST']}/webhooks/neo"), {'type' => 'transaction', 'hash' => block_txn.fetch('txid')})
          end
        end
      end
    end

    def get_block_details(block_num)
      handle(:getblock, block_num, 1)
    end

    def get_neo_asset_id
      Currency.find_by_code("neo")[:neo_asset_id]
    end

    def invalid_eth_transaction?(block_txn)
      block_txn.fetch(:to).blank? \
      || block_txn.fetch(:value).hex.to_d <= 0 && block_txn.fetch(:input).hex <= 0 \
    end

    def invalid_erc20_transaction?(txn_receipt)
      txn_receipt.fetch(:status) != SUCCESS \
      || txn_receipt.fetch(:to).blank? \
      || txn_receipt.fetch(:logs).blank?
    end

    def gettransaction txid
      handle :getrawtransaction, txid, 1
    end

    def get_accounts
      handle :listaddress
    end

    def to_address tx
      if tx.has_key?(:logs)
        get_erc20_addresses(tx)
      else
        [normalize_address(tx.fetch(:to))]
      end.compact
    end

    def get_erc20_addresses(tx)
      tx.fetch(:logs).map do |log|
        next if log.fetch('topics').blank? #|| log.fetch('topics')[0] != TOKEN_EVENT_IDENTIFIER
        normalize_address('0x' + log.fetch('topics').last[-40..-1])
      end
    end

    def convert_from_base_unit value
      (value.to_i / 1e18).to_d
    end

    def convert_to_base_unit value
      (value.to_f * 1e18).to_i
    end

    def validateaddress address
      response = handle(:validateaddress, address)
      {:isvalid => response[:isvalid]}
    end
  end

end
