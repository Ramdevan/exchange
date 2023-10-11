class Web3Currency
    WEB3_URL = "http://127.0.0.1:9003"
    WEB3_NODE_API = "http://3.99.102.84:7392"
    ZERO = 0.to_d

    def self.http_request(uri)
        path    = uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}"
        http    = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(path)
        request.content_type = 'application/json'
        response = http.request(request).body
        JSON.parse( response )
    end

    def self.http_post_request(uri, post_body)
       path    = uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}"
       http    = Net::HTTP.new(uri.host, uri.port)
       request = Net::HTTP::Post.new(path)
       request.content_type = 'application/json'
       request.body = post_body.to_json
       response = http.request(request).body
       JSON.parse( response )
    end

    def self.get(currency_code)
        currency  = Currency.find_by_code(currency_code)
        uri       = URI( currency.rpc )
        ssl_status  = (uri.to_s.split(':').first  == 'http') ? false : true
        default_connect_option = {use_ssl: ssl_status }
        web3      = Web3::Eth::Rpc.new({host: uri.host, port: uri.port, connect_options: default_connect_option})
        addresses = web3.eth.accounts
        balances  = {}

        total_balance = addresses.inject(0) do |sum, address|
            if currency_code == currency.dependant_node
                balance = get_balance(currency_code, address)
            else
                balance = get_token_balance(currency_code, address)
            end

            balances[address] = balance if balance.try(:to_f) > 0
            sum + balance
        end
        Rails.cache.write("axios:#{currency_code}_balances", balances)
        Rails.cache.write("axios:#{currency_code}_total_balance", total_balance)

        total_balance
    end

    def self.get_balance(currency_code, address)
        uri = URI("#{WEB3_URL}/#{currency_code}/balance/#{address}")
        balance  = ZERO

        begin
            response = self.http_request(uri)
            balance = (response.to_i / 1e18).to_d
        rescue => e
            Rails.logger.error "ERROR: Unable to fetch balance for Currency: #{currency_code}, Address: #{address}"
        end

        balance
    end

    def self.get_token_balance(currency_code, address)
        currency = Currency.find_by_code(currency_code)
        uri      = URI("#{WEB3_URL}/#{currency.dependant_node}/contractbalance/#{address}?contractAddress=#{currency.erc20_contract_address}")
        balance  = ZERO

        begin
            response = self.http_request(uri)
            balance = (response.to_i / 10 ** currency[:precision]).to_d
        rescue => e
            Rails.logger.error "ERROR: Unable to fetch balance for Currency: #{currency_code}, Address: #{address}"
        end

        balance
    end

    def self.send_transaction(currency_code, tx)
        currency = Currency.find_by_code(currency_code)
        #tx[:address].downcase == currency[:assets]['accounts'].first['address'].downcase ? password = currency.erc20_address_password : password = 'usdt'
        password = ""
        key_uri  = URI("#{WEB3_NODE_API}/getKey")
        transfer_uri = URI("#{WEB3_NODE_API}/#{currency.code == currency.dependant_node ? 'eth_transfer' : 'transfer'}")
        txid     = ""
        begin
            key = self.http_post_request(key_uri, {address: tx[:address], password: password, chain: currency.dependant_node})["key"]
            data = {key: key, value: tx[:value], to: tx[:to_address], amount: tx[:token_value], decimal: tx[:decimals], contract_address: currency.erc20_contract_address, chain: currency.dependant_node}
            txid = self.http_post_request(transfer_uri, data)["txHash"]
        rescue => e
           Rails.logger.error "ERROR: Failed to send signed transaction: #{e}, rawTx: #{tx}"
        end

        txid
    end

    def self.createaddress(currency_code)
        currency = Currency.find_by_code(currency_code)
        key_uri  = URI("#{WEB3_NODE_API}/CreateAccount")
        begin
        address = self.http_post_request(key_uri, {currency: currency_code})["account"]
        rescue => e
            Rails.logger.error "ERROR: Unable to create address for Currency: #{currency_code}"
        end
        address
    end

    def self.unlockaccount(unlock_address)
        key_uri  = URI("#{WEB3_NODE_API}/UnlockAccount")
        begin
        address = self.http_post_request(key_uri, {address: unlock_address})
        rescue => e
            Rails.logger.error "ERROR: Unable to unlock account for Address: #{address}"
        end
        address
    end

end
