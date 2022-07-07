class Web3Currency
    WEB3_URL = "http://127.0.0.1:9003"
    ZERO = 0.to_d

    def self.http_request(uri)
        path    = uri.query.nil? ? uri.path : "#{uri.path}?#{uri.query}"
        http    = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(path)
        request.content_type = 'application/json'
        response = http.request(request).body
        JSON.parse( response )
    end

    def self.get(currency_code)
        currency  = Currency.find_by_code(currency_code)
        uri       = URI( currency.rpc )
        web3      = Web3::Eth::Rpc.new({host: uri.host, port: uri.port})
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
        Rails.cache.write("ultimate:#{currency_code}_balances", balances)
        Rails.cache.write("ultimate:#{currency_code}_total_balance", total_balance)

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
            balance = (response.to_i / 1e6).to_d
        rescue => e
            Rails.logger.error "ERROR: Unable to fetch balance for Currency: #{currency_code}, Address: #{address}"
        end

        balance
    end
end