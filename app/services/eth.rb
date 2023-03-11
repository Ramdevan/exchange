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
        begin
          block_number = handle(:eth_blockNumber).hex
          block_number = handle(:eth_syncing)[:currentBlock].hex if block_number.zero?

          block_number
        rescue
          handle(:eth_blockNumber).hex
        end
      end
    end

    def normalize_address(address)
      address.downcase
    end

    def safe_getbalance
      begin
        Rails.cache.fetch "profitaxis:#{@currency[:code]}_total_balance" do
          Web3Currency.get(@currency[:code])
        end
      rescue
        'N/A'
      end
    end

    def getaddress_balance(address, currency)
      begin
        Web3Currency.get_balance(currency, address)
      rescue
        'N/A'
      end
    end

    def gettransaction txid
      handle :eth_getTransactionByHash, txid
    end

    def listtransactions latest_block=nil, diff=20
 
      if latest_block
        from_block = latest_block - diff
        to_block = latest_block
      else
        from_block, to_block = get_processing_blocks
      end

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

    def find_or_initialize_address(member_id)
      accounts = Account.where(member_id: member_id, currency: get_all_dependant_currency_ids).includes(:payment_addresses)
      address = nil

      accounts.each do |account|
        address = account.try(:payment_address).try(:address)
        break if address.present?
      end

      address = getnewaddress unless address.present?
      address
    end

    def getnewaddress label = ''
      handle :personal_newAccount, label
    end

    def get_all_dependant_currency_ids
      current_node_coins.map(&:id)
    end

    def current_node_coins
      Currency.where(dependant_node: @currency[:dependant_node])
    end

    def get_all_contract_address
      current_node_coins.map(&:erc20_contract_address).compact
    end

    def get_processing_blocks
      diff = 20
      latest_block ||= latest_block_number

      last_checked_block = get_block_diff
      if last_checked_block > 0
        blocks_to_check = latest_block - last_checked_block
        diff = (blocks_to_check)/100 > 0 ? 100 : blocks_to_check
        Rails.cache.write("profitaxis:#{@currency[:dependant_node]}:balance_blocks", last_checked_block + diff)
      else
        Rails.cache.write("profitaxis:#{@currency[:dependant_node]}:balance_blocks", latest_block)
      end
      from_block = last_checked_block
      to_block = last_checked_block + diff

      Rails.logger.info "#{@currency[:dependant_node].try(:upcase)} blocks | latest_block: #{latest_block} | from block: #{from_block} | to block: #{to_block}" if from_block != to_block

      [from_block, to_block]
    end

    def get_block_diff
      latest_block = latest_block_number
      balance_blocks = Rails.cache.read("profitaxis:#{@currency[:dependant_node]}:balance_blocks").to_i
      previous_block = ( balance_blocks >= 0 && balance_blocks <= latest_block ) ? balance_blocks : 0

      previous_block
    end

    def sendtoaddress(from, to, amount)
      base_amount = '0x' + convert_to_base_unit(amount).to_s(16)
      handle :eth_sendTransaction, {from: normalize_address(from), to: normalize_address(to), value: base_amount}
    end

  end
end
