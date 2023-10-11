
require 'net/http'
require 'net/https'

class CoinRPC

  class BNB < self

    SUCCESS = '0x1'

    def handle(name, local=false, *args)
      post_body = {"jsonrpc" => "2.0", 'method' => name, 'params' => args, 'id' => '1'}.to_json
      resp = http_post_request(post_body, local)
      unless resp.blank?
        parsed_resp = JSON.parse(resp)
        raise JSONRPCError, parsed_resp['error'] if parsed_resp['error']
        result = parsed_resp['result']
        result.symbolize_keys! if result.is_a? Hash
        result
      end
    end

    def http_post_request(post_body, local)
      @current_uri = (local ==true) ? @uri : @public_uri
      http    = Net::HTTP.new(@current_uri.host, @current_uri.port)
      request = Net::HTTP::Post.new(@current_uri.request_uri)
      ssl_status  = (@current_uri.to_s.split(':').first  == 'http') ? false : true
      http.use_ssl = ssl_status
      request.content_type = 'application/json'
      request.body = post_body
      res = http.request(request)
      res.code.to_i == 200.to_i ? res.body : nil
      rescue Errno::ECONNREFUSED => e
        ExceptionNotifier.notify_exception(e)
      raise ConnectionRefusedError
    end

    def latest_block_number
      Rails.cache.fetch :latest_bsc_block_number, expires_in: 5.seconds do
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
        Web3Currency.get(@currency[:code])
      rescue
        'N/A'
      end
    end

    def getaddress_balance(address,currency)
      begin
        Web3Currency.get_balance(currency, address)
      rescue
        'N/A'
      end
    end

    def gettransaction txid
      handle(:eth_getTransactionByHash, false, txid)
    end

    def listtransactions latest_block=nil, diff=20
      latest_block ||= latest_block_number
      channel = DepositChannel.find_by(key: @currency[:code])

      diff_block = get_blok_diff
      diff = diff_block > 0 ?  latest_block - diff_block : 20
      from_block = latest_block - diff
      to_block = latest_block
      Rails.logger.info "diff #{diff},latest_block #{latest_block}, diff block #{diff_block}"
      (from_block..to_block).each do |block_id|
        re_exec_transaction(block_id)
      end
    end

    def re_exec_transaction(block_id)
      re_exec_transaction(block_id) unless exec_transaction(block_id)
    end

    def exec_transaction(block_id)
      begin
        block_json = get_block block_id
        missing_block = MissingBlock.where(block_id: block_id, currency: @currency[:code]).first_or_initialize
        if block_json.blank?
          DepositTrackLogger.debug("block id: #{block_id}-- block json blank #{@currency[:code]}")
          missing_block.status = false
          missing_block.save
          return true
        elsif block_json[:transactions].blank?
          #Even block has no transactions
          DepositTrackLogger.debug("block id: #{block_id}-- block json present but transaction is blank")
          missing_block.status = true
          missing_block.save unless missing_block.new_record?
          return true
        else
          DepositTrackLogger.debug("block id: #{block_id}-- block json present and transaction is present #{@currency[:code]}")
          missing_block.status = true
          missing_block.save unless missing_block.new_record?
        end

        all_accounts = get_accounts
        block_json[:transactions].each do |block_txn|
          if all_accounts.include?(block_txn.with_indifferent_access['to']) || Currency.all.map(&:erc20_contract_address).compact.map(&:downcase).include?(block_txn.with_indifferent_access['to'])
            if block_txn.with_indifferent_access.fetch('input').hex <= 0
              next if invalid_eth_transaction?(block_txn.symbolize_keys)
              AMQPQueue.enqueue(:deposit_coin, txid: block_txn.with_indifferent_access.fetch('hash'), channel_key: 'bnb')
            else
              txn_receipt = get_txn_receipt(block_txn.with_indifferent_access.fetch('hash'))
              next if txn_receipt.nil? || invalid_erc20_transaction?(txn_receipt.symbolize_keys) || (all_accounts.exclude?(to_address(txn_receipt).first))
              currency_with_erc20_contract_addresses = Currency.all.select{|c| c.erc20_contract_address!= nil }
              currency_with_erc20_contract_address = currency_with_erc20_contract_addresses.select{|a| a.erc20_contract_address.downcase == block_txn.with_indifferent_access['to']}
              currency_key = currency_with_erc20_contract_address.first.key
              next if currency_key.blank?
              AMQPQueue.enqueue(:deposit_coin, txid: block_txn.with_indifferent_access.fetch('hash'), channel_key: currency_key)
            end
          end
        end
        true
      rescue => e
       DepositTrackLogger.debug("block id #{block_id} is failed.Error: #{e}")
       true
      end
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
      Web3Currency.createaddress(@currency[:code])
    end

    def get_block(height)
      current_block   = height || 0
      handle(:eth_getBlockByNumber, false,"0x#{current_block.to_s(16)}", true)
    end

    def current_node_coins
      Currency.where(dependant_node: @currency[:dependant_node])
    end

    def get_all_contract_address
      current_node_coins.map(&:erc20_contract_address).compact
    end

    def get_all_dependant_currency_ids
      current_node_coins.map(&:id)
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
      handle(:eth_getTransactionReceipt, false, txid)
    end

    def get_accounts
      handle(:eth_accounts,true)
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

    def sendtoaddress(from, to, amount)
      txid = ""
      base_amount = '0x' + convert_to_base_unit(amount).to_s(16)
      txid = Web3Currency.send_transaction(@currency[:code], {address: from, to_address: to, value: amount.to_s})

      txid
    end

    private

    def get_blok_diff
      latest_block = latest_block_number
      balance_blocks = Rails.cache.read("axios:bnb:balance").to_i
      previous_block = ( balance_blocks > 0 && balance_blocks < latest_block ) ? balance_blocks : 0

      Rails.cache.write("axios:bnb:balance", latest_block)

      previous_block
    end
  end

  class BUSD < BNB

    def getnewaddress label = ''
      Web3Currency.createaddress(@currency[:code])
    end

    def get_contract_address
      contract_address
    end

    def sendtoaddress(from, to, amount)
      txid = ""
      converted_amount = convert_to_base_unit(amount)
      txid = Web3Currency.send_transaction(@currency[:code], {address: from, to_address: to, token_value: converted_amount.to_f})

      txid
    end

    def abi_encode(method, *args)
      '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
        data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
      end
    end

    def safe_getbalance
      begin
        Web3Currency.get(@currency[:code])
      rescue
        'N/A'
      end
    end

    def erc20_balance address, currency
      begin
        Web3Currency.get_token_balance(currency, address)
      rescue
        'N/A'
      end
    end

    def convert_from_base_unit value
      (value.to_i / 1e18).to_d
    end

    def convert_to_base_unit value
      (value.to_f * 1e18).to_i
    end

    private

    def contract_address
      normalize_address(@currency[:erc20_contract_address])
    end

  end

  class USDT < BUSD

   def sendtoaddress(from, to, amount)
      txid = ""
      converted_amount = convert_to_base_unit(amount)
      txid = Web3Currency.send_transaction(@currency[:code], {address: from, to_address: to, token_value: converted_amount.to_s})

      txid
    end

    def convert_from_base_unit value
      (value.to_i / 1e18).to_d
    end

    def convert_to_base_unit value
      (value.to_f * 1e18).to_i
    end
  end

end
