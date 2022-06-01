module APIv2
    class StakeCoins < Grape::API
        helpers ::APIv2::NamedParams

        before { authenticate! }

        desc 'Get list of stake plans available to invest.', scopes: %w(invest)
        params do
        use :auth
        optional :limit, type: Integer, default: 100, range: 1..1000, desc: "Limit the number of returned stake plans, default to 100."
        optional :page,  type: Integer, values: 1..1000, default: 1, desc: "Specify the page of paginated results."
        end
        get "/stake_coins" do
            stake_coins = StakeCoin.all.includes(:current_variable_apy)
                        .order(:id)
                        .page(params[:page])
                        .per(params[:limit])

            present :count, stake_coins.total_count
            present :stake_coins, stake_coins, with: APIv2::Entities::StakeCoin
        end
    end
end