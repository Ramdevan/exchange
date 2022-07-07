module Admin
    class AdminWithdrawsController < BaseController
  
      def index
        @balances  = {}
        
        Currency::DEPENDENT_NODES.each do |currency_code|
          currency = Currency.find_by(code: currency_code)
          next unless currency.present?
  
          address  = currency[:assets]["accounts"][0]["address"]
          dependent_coins = Currency.get_dependent_coins(currency_code)
          @balances[currency_code] = {
            balance: check_balance(dependent_coins, address),
            common_address: address,
            dependent_coins: dependent_coins,
            address_with_balance: address_balance(dependent_coins, address)
          }
        end
  
        @balances
      end
  
      def make_transaction
        amount        = params["amount"].to_d
        to_address    = params["to_address"]
        from_address  = params["from_address"]
        currency_code = params["token"]
        currency      = Currency.find_by_code(currency_code)
        node          = currency.dependant_node
        message       = {
          alert: "Insufficient Balance to Make transaction"
        }
  
        begin
          if Currency::DEPENDENT_NODES.include? currency_code.to_sym
            balance = CoinRPC[currency_code].getaddress_balance(from_address,currency_code)
            if balance != "N/A" && balance.to_d > amount
              if currency_code.to_sym == :trx
                if CoinRPC['trx'].get_common_withdrawl_account['address'] == from_address
                  source_account = CoinRPC['trx'].get_common_withdrawl_account
                else
                  source_account = CoinRPC[currency_code].get_account(from_address)
                end
                private_key = source_account['privateKey']
                txid = CoinRPC[currency_code].sendtoaddress(to_address, amount, private_key)
              else
                CoinRPC[currency_code].personal_unlockAccount(from_address, "", 5000)
                txid = CoinRPC[currency_code].sendtoaddress(from_address, to_address, amount)
              end
  
              message[:notice] = "The transaction is Successful #{txid}" if txid
            end
          else
            gas_fee = CoinRPC[node].getaddress_balance(from_address, node)
  
            if gas_fee == "N/A" || gas_fee.to_f <= 0.0
              message[:alert] = "Insufficient #{node.try(:upcase)} for gas fee"
            else
              balance = CoinRPC[currency_code].erc20_balance(from_address, currency_code)
              if balance != "N/A" && balance.to_d >= amount
                CoinRPC[currency_code].personal_unlockAccount(from_address, "", 5000)
                txid = CoinRPC[currency_code].sendtoaddress(from_address, to_address, amount)
  
                message[:notice] = "The transaction is Successful #{txid}" if txid
              end
            end
          end
          message.delete(:alert) if message.has_key? :notice
  
          redirect_to admin_admin_withdraws_path, message
        rescue => e
          ExceptionNotifier.notify_exception(e, env: request.env)
          Rails.logger.info  "Error on Transaction: #{$!}"
          redirect_to admin_admin_withdraws_path, alert:"Error on Transaction: #{e}"
        end
      end
  
      private
  
      def check_balance(tokens, address)
        hot_balance = Hash.new()
        tokens.each do |token|
          if Currency::DEPENDENT_NODES.include? token.to_sym
            balance = CoinRPC[token].getaddress_balance(address, token.to_s)
            hot_balance[token] = balance == "N/A" ? 0.0 : balance
          else
            balance = CoinRPC[token].erc20_balance(address, token.to_s)
            hot_balance[token] = balance == "N/A" ? 0.0 : balance
          end
        end
  
        hot_balance
      end
  
      def address_balance(currencies, address)
        hot_wallet = Hash.new()
  
        currencies.each do |currency|
          begin
            hot_wallet[currency] = Rails.cache.read("ultimate:#{currency}_balances")
          rescue => e
            Rails.logger.info "ERROR: Unable to fetch balance for currency: #{currency}"
            next
          end
        end
  
        hot_wallet
      end
    end
  end
  