class VariableApy < ActiveRecord::Base
    self.table_name = 'variable_apy'
    belongs_to :stake_coin
    after_commit :update_variable_apy_id

    def update_variable_apy_id
        stake_coin = self.stake_coin
        stake_coin.variable_apy.order(:lot_size).each do |apy|
            stake_coin.variable_apy_id = apy.id
            break if apy.lot_size > stake_coin.cur_lot_size
        end
        # if stake_coin.variable_apy_id_changed? || self.id == stake_coin.variable_apy_id
        #     stake_coin.member_stake_coin.where(aasm_state: [:accepted,:submitted]).each do |mem_stake_coin|
        #         mem_stake_coin.calculate_interest_per_day(stake_coin)
        #         mem_stake_coin.save
        #     end
        # end
        stake_coin.save
    end
end
