module APIv2
  class Markets < Grape::API

    desc 'Get all available markets.'
    get "/markets" do
      present Market.stats, with: APIv2::Entities::Market
    end

    desc 'Get all available markets for a currency.'
    get "/:currency/markets" do
      present Market.trading_pairs(params[:currency]), with: APIv2::Entities::Market
    end

    desc 'Get the balance of a currency.'
    get "/balance/:currency" do
      account = current_user.accounts.find_by_currency(params[:currency])
      currency = Currency.find_by_code(params[:currency])
      balance = "0.0"
      balance = account.balance_precision if account
      locked = account.locked if account
      currency = currency.attributes.merge(balance: balance, locked: locked, fiat: !Currency.crypto_coin_codes.include?(params[:currency]))

      present currency, with: APIv2::Entities::Currency
    end

    desc 'Get all available currencies.'
    get "/currencies" do
      present :currencies, Account.currency_details(current_user.id), with: APIv2::Entities::Currency
    end

  end
end
