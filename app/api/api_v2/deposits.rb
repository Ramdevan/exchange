require_relative 'validations'

module APIv2
  class Deposits < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }

    desc 'Get your deposits history.'
    params do
      use :auth
      currencies = Currency.codes
      requires :currency, type: String, values: currencies + currencies.map(&:upcase), desc: "Currency value contains  #{currencies.join(',')}"
      optional :limit, type: Integer, range: 1..1000, default: 100, desc: "Set result limit."
      optional :page, type: Integer, values: 1..1000, default: 1, desc: "Page number (defaults to 1)."
      optional :order_by, type: String, values: %w(asc desc), default: 'desc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
      optional :state, type: String, values: Deposit::STATES.map(&:to_s)
    end
    get "/history/deposit/:currency" do
      deposits = current_user
                     .deposits
                     .order(order_param)
                     .tap { |q| q.where!(currency: params[:currency].downcase) if params[:currency] }
                     .page(params[:page])
                     .per(params[:limit])
      deposits = deposits.with_aasm_state(params[:state]) if params[:state].present?

      present :count, deposits.total_count
      present :history, deposits, with: APIv2::Entities::Deposit
    end

    desc 'Get details of specific deposit.'
    params do
      use :auth
      requires :txid
    end
    get "/deposit/transaction/:txid" do
      deposit = current_user.deposits.find_by(txid: params[:txid])
      raise DepositByTxidNotFoundError, params[:txid] unless deposit

      present deposit, with: APIv2::Entities::Deposit
    end

    desc 'Where to deposit. The address field could be empty when a new address is generating (e.g. for bitcoin), you should try again later in that case.'
    params do
      use :auth
      currencies = Currency.codes
      requires :currency, type: String, values: currencies + currencies.map(&:upcase), desc: "The account to which you want to deposit. Available values: #{currencies.join(', ')}"
    end
    get "/deposit/address/:currency" do
      currency = params[:currency]
      if Currency.crypto_coin_codes.include?(currency)
        account = current_user.ac(currency)
        payment_address = account.payment_address
        if payment_address.address.blank?
          sleep(5)
        end

        deposit_address = payment_address.deposit_address
        if Currency::TAGS_REQUIRED.include? currency.to_sym
          return :fiat => false, :address => deposit_address, :destination_tag => payment_address.destination_tag
        else
          return :fiat => false, :address => deposit_address
        end
      else
        return :fiat => true, :account_name => "", :account => '', :bank_name => "Bank", :bank_code => "" #TODO: Move this to config
      end
    end
    
    get "/deposit/fiat/account/:currency" do
      currency = params[:currency]
      res = []
      sources = current_user.fund_sources.where(currency: currency)
      sources.each do |source|
        res << {id: source.id, account_name: current_user.name, account: source.uid, bank_name: source.extra, bank_code: source.bank_code}
      end
      return res
    end

    params do
      currencies = Currency.codes
      requires :currency, type: String,  values: currencies + currencies.map(&:upcase), desc: "Any supported currency: #{currencies.join(',')}."
      requires :extra, type: String, desc: "Provide a Label for your address."
      requires :uid, type: String, desc: "Destination address in which the currency gets deposited."
      optional :bank_code, type: String, desc: "Bank Identification code."
      optional :destination_tag, type: String, desc: "Destination tag for #{Currency::TAGS_REQUIRED.join(',')} currencies"
    end

    post "/deposit/fiat/account/:currency" do
      currency_params = params.as_json(only: %i[currency extra uid bank_code destination_tag])
      new_fund_source = current_user.fund_sources.new currency_params
      ok = new_fund_source.save

      if ok
        return new_fund_source
      else
        raise CustomError.new("Unable to add deposit address.")
      end
    end

    delete "/deposit/fiat/account/:id" do
      fund_source = FundSource.find_by_id(params[:id])
      fund_source.delete if fund_source

      if fund_source && fund_source.deleted?
        return :success => {message: "Deposit account deleted successfully."}
      elsif fund_source == nil
        raise CustomError.new("Deposit account not found.")
      else
        raise CustomError.new("Unable to delete deposit account.")
      end
    end

    params do
      currencies = Currency.codes
      requires :currency, type: String,  values: currencies + currencies.map(&:upcase), desc: "Any supported currency: #{currencies.join(',')}."
      requires :fund_source, type: String, desc: "Provide a fund source."
      requires :amount, type: Integer, desc: "Amount to deposit"
    end

    post "/deposit/fiat/:currency" do
      deposit_params = params.as_json(only: %i[fund_source amount currency])
      currency = params[:currency]
      account = current_user.ac(currency)
      deposit_params[:member_id] = current_user.id
      deposit_params[:account_id] = account.id
      bank_deposit = "Deposits::Bank".constantize.new deposit_params
      ok = bank_deposit.save

      if ok
        return bank_deposit
      else
        raise CustomError.new("Unable to deposit.")
      end
    end
  end
end
