module APIv2
    class MemberStakeCoins < Grape::API
        helpers ::APIv2::NamedParams

        before { authenticate! }

        desc 'Get list of stake plans in which user has invested.', scopes: %w(invest)
        params do
        use :auth
        requires :stake_coin_id, type: Integer, desc: "Stake coin for which member's investment history needs to be fetched."
        optional :limit, type: Integer, default: 100, range: 1..1000, desc: "Limit the number of returned stake plans, default to 100."
        optional :page,  type: Integer, values: 1..1000, default: 1, desc: "Specify the page of paginated results."
        end
        get "/member_stake_coins" do
            member_stake_coins = MemberStakeCoin.where(member_id: current_user.id, stake_coin_id: params[:stake_coin_id]).includes(:stake_coin,stake_coin: :current_variable_apy)
                                                .order(:id)
                                                .page(params[:page])
                                                .per(params[:limit])

            present :count, member_stake_coins.total_count
            present :member_stake_coins, member_stake_coins, with: APIv2::Entities::MemberStakeCoin
        end

        desc 'Invest in a stake plan.', scopes: %w(invest)
        params do
        use :auth
        requires :stake_coin_id, type: Integer, desc: "Stake coin in which member wants to invest."
        requires :amount, type: Float, desc: "Number of coins member wants to invest in the plan."
        end
        post "/member_stake_coins" do
            member_stake_coin = MemberStakeCoin.new(stake_coin_id: params[:stake_coin_id], amount: params[:amount])
            member_stake_coin.member_id = current_user.id
            member_stake_coin.start_date = Time.zone.now
            stake_coin = StakeCoin.where(id: member_stake_coin.stake_coin_id).first
            raise StakeCoinNotFoundError, params[:stake_coin_id] unless stake_coin
            exisiting_member_stake_coins = MemberStakeCoin.where(member_id: current_user.id, stake_coin_id: stake_coin.id, aasm_state: :accepted)
            current_staked_amount = 0.0
            exisiting_member_stake_coins.each do |exisiting_member_stake_coin|
                current_staked_amount += exisiting_member_stake_coin.amount
            end
            if(current_staked_amount + member_stake_coin.amount > stake_coin.max_deposit)
                raise CreateMemberStakeCoinError, "Max limit is #{stake_coin.max_deposit}"
            end
            if(stake_coin.min_deposit > member_stake_coin.amount || stake_coin.max_deposit < member_stake_coin.amount)
                raise CreateMemberStakeCoinError, "Investment amount should be in the range #{stake_coin.min_deposit} and #{stake_coin.max_deposit}"
            end
            unless(stake_coin.is_flexible)
                member_stake_coin.end_date = (Time.zone.now + stake_coin.duration.days).end_of_day
            end
            if stake_coin.max_lot_size < (stake_coin.cur_lot_size + member_stake_coin.amount)
                raise CreateMemberStakeCoinError, "Maximum investement amount for the plan is reached."
            end
            
            account = Account.where(member_id: current_user.id, currency: stake_coin.currency).first
            if account.balance < member_stake_coin.amount
                raise CreateMemberStakeCoinError, "Balance not enough"
            end
            unless member_stake_coin.save
                raise CreateMemberStakeCoinError, "Save Failed"
            end
            member_stake_coin.submit!
            present :member_stake_coin, member_stake_coin, with: APIv2::Entities::MemberStakeCoin
        end


        desc 'Redeem Flexible stake investments.', scopes: %w(invest)
        params do
        use :auth
        requires :id, type: Integer, desc: "Member stake coin which needs to be redeemed."
        end
        put "/member_stake_coins/:id" do
            member_stake_coin = MemberStakeCoin.where(id: params[:id]).first

            raise MemberStakeCoinNotFoundError, params[:id] unless member_stake_coin
            unless member_stake_coin.stake_coin.is_flexible
                raise RedeemLockedInvestmentError, "Cannot modify locked staking."
            end
            member_stake_coin.end_date = Time.zone.now
            member_stake_coin.mature
            member_stake_coin.save
            present :member_stake_coin, member_stake_coin, with: APIv2::Entities::MemberStakeCoin
        end

    end
end