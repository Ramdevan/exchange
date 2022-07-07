namespace :web3_currency do
    desc 'Get all the address balances of each currencies'
    task get_address_balances: :environment do
      Currency::DEPENDENT_NODES.each do |currency_code|
        currency_obj = Currency.find_by(code: currency_code)
        next unless currency_obj.present?
  
        common_address  = currency_obj[:assets]["accounts"][0]["address"]
        dependent_currencies = Currency.get_dependent_coins(currency_code)
  
        dependent_currencies.each do |currency|
          begin
        balance = Web3Currency.get(currency.to_s)
            Rails.logger.info "INFO: Balance #{balance} for currency: #{currency}"
          rescue => e
            Rails.logger.info "ERROR: Unable to fetch balance for currency: #{currency}"
            next
          end
        end
      end
    end
  end
  