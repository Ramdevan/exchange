require 'net/http'
require 'net/https'

class CoinRPC

  class ETH < self

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
      http    = Net::HTTP.new(@uri.host, @uri.port)
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.content_type = 'application/json'
      request.body = post_body
      http.request(request).body
    rescue Errno::ECONNREFUSED => e
      ExceptionNotifier.notify_exception(e)
      raise ConnectionRefusedError
    end

    def latest_block_number
      Rails.cache.fetch :latest_ethereum_block_number, expires_in: 5.seconds do
        handle(:eth_blockNumber).hex
      end
    end

    def normalize_address(address)
      address.downcase
    end

    def safe_getbalance
      begin
        EthereumBalance.get
      rescue
        'N/A'
      end
    end

    def gettransaction txid
      handle :eth_getTransactionByHash, txid
    end

    def listtransactions latest_block=nil, diff=20
      latest_block ||= latest_block_number

      from_block = latest_block - diff
      to_block = latest_block

      (from_block..to_block).each do |block_id|
        block_json = get_block block_id
        next if block_json.blank? || block_json[:transactions].blank?

        all_accounts = get_accounts
        block_json[:transactions].each do |block_txn|
          if all_accounts.include?(block_txn['to']) || Currency.all.map(&:erc20_contract_address).compact.include?(block_txn['to'])
            if block_txn.fetch('input').hex <= 0
              next if invalid_eth_transaction?(block_txn.symbolize_keys)
              AMQPQueue.enqueue(:deposit_coin, txid: block_txn.fetch('hash'), channel_key: 'ether')
            else
              txn_receipt = get_txn_receipt(block_txn.fetch('hash'))
              next if txn_receipt.nil? || invalid_erc20_transaction?(txn_receipt.symbolize_keys) || (all_accounts.exclude?(to_address(txn_receipt).first))
              currency_key = Currency.where(erc20_contract_address: block_txn['to']).first.key rescue nil
              next if currency_key.blank?
              AMQPQueue.enqueue(:deposit_coin, txid: block_txn.fetch('hash'), channel_key: currency_key)
            end
          end
        end
      end
    end

    def get_block(height)
      current_block   = height || 0
      handle :eth_getBlockByNumber, "0x#{current_block.to_s(16)}", true
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

    def get_txn_receipt(txid)
      handle :eth_getTransactionReceipt, txid
    end

    def get_accounts
      handle :eth_accounts
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
      eth_address_regex = /^0x[a-fA-F0-9]{40}$/
      eth_address_regex.match(address) ? {isvalid: true} : {isvalid: false}
    end
  end

  class USDT < ETH

    def getnewaddress label
      handle :personal_newAccount, ''
    end

    def get_contract_address
      contract_address
    end

    def sendtoaddress from, to, amount
      data = abi_encode 'transfer(address,uint256)', normalize_address(to), '0x' + convert_to_base_unit(amount).to_s(16)
      txid = handle :eth_sendTransaction, {from: normalize_address(from), to: contract_address, data: data}
      txid
    end

    def abi_encode(method, *args)
      '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
        data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
      end
    end

    def safe_getbalance
      begin
        Rails.cache.fetch "xubiq:#{@currency[:key]}_erc20_balance", expires_in: 60.seconds do
          EthereumBalance.get_erc20 @currency
        end
      rescue
        'N/A'
      end
    end

    def convert_from_base_unit value
      (value.to_i / 1e6).to_d
    end

    def convert_to_base_unit value
      (value.to_f * 1e6).to_i
    end

    private

    def contract_address
      normalize_address(@currency[:erc20_contract_address])
    end

  end

  class USDC < USDT

    def convert_from_base_unit value
      (value.to_i / 1e2).to_d
    end

    def convert_to_base_unit value
      (value.to_f * 1e2).to_i
    end

  end

end
