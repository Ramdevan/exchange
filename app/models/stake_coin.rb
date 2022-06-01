class StakeCoin < ActiveRecord::Base
    has_many :variable_apy, dependent: :destroy
    has_many :member_stake_coin
    belongs_to :current_variable_apy, class_name: "VariableApy", foreign_key: :variable_apy_id
    include Currencible
    accepts_nested_attributes_for :variable_apy, allow_destroy: true, reject_if: :all_blank
    before_save :update_variable_apy_id
    validates_uniqueness_of :currency, scope: :duration, message: "For the currency and duration selected, Stake option already exists!"
    validate :check_if_apy_is_added


    def update_variable_apy_id
        if self.cur_lot_size_changed?
            self.variable_apy.order(:lot_size).each do |apy|
                self.variable_apy_id = apy.id
                break if apy.lot_size > self.cur_lot_size
            end
        end
        # if self.variable_apy_id_changed?
        #     self.member_stake_coin.where(aasm_state: [:accepted,:submitted]).each do |mem_stake_coin|
        #         mem_stake_coin.calculate_interest_per_day(self)
        #         mem_stake_coin.save
        #     end
        # end
    end
    def check_if_apy_is_added
        errors.add(:base, "Should have atleast one apy.") if self.variable_apy.empty?
    end
end
