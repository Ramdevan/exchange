module APIv2
    class MemberStakeCoinCreditHistories < Grape::API
        helpers ::APIv2::NamedParams

        before { authenticate! }

        desc 'Get list of interest credited for the stake coin plan.', scopes: %w(invest)
        params do
        use :auth
        requires :member_stake_coin_id, type: Integer, desc: "Member stake coin for which credit history needs to be fetched."
        optional :limit, type: Integer, default: 100, range: 1..1000, desc: "Limit the number of returned interest credits, default to 100."
        optional :page,  type: Integer, values: 1..1000, default: 1, desc: "Specify the page of paginated results."
        end
        get "/member_stake_coin_credit_histories" do
            current_user = Member.first
            member_stake_coin = MemberStakeCoin.where(member_id: current_user.id, id: params[:member_stake_coin_id]).first
            raise MemberStakeCoinNotFoundError, params[:member_stake_coin_id] unless member_stake_coin

            member_stake_coin_credit_history = MemberStakeCoinCreditHistory.where(member_stake_coin_id: member_stake_coin.id).order(id: :desc).page(params[:page]).per(params[:limit])

            present :count, member_stake_coin_credit_history.total_count
            present :member_stake_coin_credit_history, member_stake_coin_credit_history, with: APIv2::Entities::MemberStakeCoinCreditHistory
        end
    end
end
