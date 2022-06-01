class MemberStakeCoin < ActiveRecord::Base
    extend Enumerize
    belongs_to :stake_coin
    belongs_to :member
    has_many :member_stake_coin_credit_histories
    STATES = [:submitting, :submitted, :suspect, :accepted, :matured, :completed]
    include AASM
    include AASM::Locking

    enumerize :aasm_state, in: STATES, scope: true

    aasm :whiny_transitions => false do
        state :submitting,  initial: true
        state :submitted
        state :accepted
        state :matured
        state :completed
        state :suspect
    
        event :submit do
          transitions from: :submitting, to: :submitted
          after do
            lock_funds
          end
        end
    
        event :mark_suspect do
          transitions from: :submitted, to: :suspect
        end
    
        event :accept do
          transitions from: :submitted, to: :accepted
          
          after do
            update_cur_lot_size
          end
        end

        event :mature do
            transitions from: :accepted, to: :matured
        end
    
        event :complete do
          transitions from: :matured, to: :completed
    
          after do
            unlock_funds
          end
        end
    end
    def lock_funds
        account = get_account
        account.lock!
        account.lock_funds amount, reason: Account::STAKING_LOCK, ref: self
    end
    def audit!
        with_lock do
          account = get_account
          if account.examine
            accept!
          else
            mark_suspect
          end
          save!
        end
    end
    def update_cur_lot_size
        stake_coin.cur_lot_size += amount
        stake_coin.lot_size_for_apy += amount
        stake_coin.save
    end
    def get_account
        Account.where(member_id: member_id, currency: self.stake_coin.currency).first
    end
    def interest_per_day
        interest = stake_coin.current_variable_apy.apy
        ((interest/365)*amount)/100
    end
    def unlock_funds
        account = get_account
        account.lock!
        account.unlock_funds amount, reason: Account::STAKING_UNLOCK, ref: self
      end
    # def calculate_interest_per_day(stake_coin)
    #     interest = stake_coin.current_variable_apy.apy
    #     self.interest_per_day = ((interest/365)*amount)/100
    # end
end
