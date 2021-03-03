module APIv2
  class Withdraws < Grape::API
    helpers ::APIv2::NamedParams

    before { authenticate! }

    desc 'List your withdraws as paginated collection.', scopes: %w[ history ]
    params do
      currencies = Currency.codes
      requires :currency, type: String,  values: currencies + currencies.map(&:upcase), desc: "Any supported currency: #{currencies.join(',')}."
      optional :page,     type: Integer, values: 1..1000, default: 1, desc: 'Page number (defaults to 1).'
      optional :limit,    type: Integer, default: 100, range: 1..1000, desc: 'Number of withdraws per page (defaults to 100, maximum is 1000).'
      optional :order_by, type: String, values: %w(asc desc), default: 'desc', desc: "If set, returned orders will be sorted in specific order, default to 'asc'."
    end
    get '/history/withdraw/:currency' do
      current_user
          .withdraws
          .order(order_param)
          .tap { |q| q.where!(currency: params[:currency].downcase) if params[:currency] }
          .tap { |q| present :count, q.count }
          .page(params[:page])
          .per(params[:limit])
          .tap { |q| present :history, q, with: APIv2::Entities::Withdraw }
    end

    post "/withdraw/:currency" do
      # Verify two factor
      currency = Currency.find_by_code(params[:currency])
      if two_factor_auth_verified?
        # Save withdraw
        withdraw_params = {}
        withdraw_params[:member_id] = current_user.id
        withdraw_params[:currency] = params[:currency]
        withdraw_params[:sum] = params[:sum]
        withdraw_params[:fund_source] = params[:fund_source]
        if currency.fiat?
          model = ("withdraws/bank").camelize.constantize
        else
          model = ("withdraws/"+currency.key).camelize.constantize
        end
        withdraw = model.new withdraw_params
        withdraw.save
        if withdraw.valid?
          withdraw.submit!
          return withdraw
        else
          raise CustomError.new(withdraw.errors.full_messages.join(', '))
        end
      else
        raise CustomError.new("Please enter valid OTP")
      end
    end

    get '/withdraw/address/:currency' do
      currency = params[:currency]
      currency_details = {}
      currency_details[:currecy] = currency
      currency_details[:extra] = ""
      currency_details[:uid] = ""
      begin
        if not Currency.find_by_code(currency).coin?
          raise CustomError.new("No withdrawal address for fiat currencies.")
        elsif Currency::TAGS_REQUIRED.include? currency.to_sym
          currency_details[:destination_tag] = ""
        end
        return currency_details
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        return currency_details
      end
    end

    params do
      currencies = Currency.codes
      requires :currency, type: String,  values: currencies + currencies.map(&:upcase), desc: "Any supported currency: #{currencies.join(',')}."
      requires :extra, type: String, desc: "Provide a Label for your address."
      requires :uid, type: String, desc: "Destination address in which the currency gets deposited."
      optional :bank_code, type: String, desc: "Bank Identification code."
      optional :destination_tag, type: String, desc: "Destination tag for #{Currency::TAGS_REQUIRED.join(',')} currencies"
    end
    post "/withdraw/address/:currency" do
      currency_params = params.as_json(only: %i[currency extra uid destination_tag bank_code])
      new_fund_source = current_user.fund_sources.new currency_params
      ok = new_fund_source.save

      if ok
        return new_fund_source
      else
        raise CustomError.new("Unable to add withdrawal address.")
      end
    end

    put "/withdraw/address/:currency/:id" do
      account = current_user.accounts.with_currency(params[:currency]).first
      fund_source = FundSource.find_by_id(params[:id])
      ok = account.update default_withdraw_fund_source_id: params[:id] if fund_source

      if ok
        return account.default_withdraw_fund_source
      else
        raise CustomError.new("Unable to set default withdrawl address.")
      end
    end

    get "/withdraw/addresses/:currency" do
      account = current_user.accounts.find_by_currency(params[:currency])
      fund_sources = FundSource.where(member_id: current_user.id, currency: params[:currency])
      fund_sources = fund_sources.each do |source|
          source.is_default = (source.id.to_i == account.default_withdraw_fund_source_id)
      end
      fund_sources.sort_by! { |row| [row.is_default ? 0 : 1] }

      present fund_sources, with: APIv2::Entities::FundSource
    end

    delete "/withdraw/address/:id" do
      fund_source = FundSource.find_by_id(params[:id])
      fund_source.delete if fund_source

      if fund_source && fund_source.deleted?
        return :success => {message: "Withdrawl address deleted successfully."}
      elsif fund_source == nil
        raise CustomError.new("Withdrawl address not found.")
      else
        raise CustomError.new("Unable to delete withdrawl address.")
      end
    end

    desc 'Cancel the pending withdrawl request.'
    delete "/withdraw/:id" do
      Withdraw.transaction do
        withdraw = current_user.withdraws.find(params[:id])
        if withdraw.aasm_state == "submitted"
          withdraw.lock!
          withdraw.cancel
          withdraw.save!
          present :success => {message: "Withdraw cancelled successfully."}
        elsif withdraw.aasm_state == "canceled"
          raise CustomError.new("Withdraw is already cancelled.")
        else
          raise CustomError.new("Withdraw cannot be cancelled, because it is #{withdraw.aasm_state}.")
        end
      end
    end
  end
end
