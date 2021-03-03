module Admin
  class Ability
    include CanCan::Ability

    def initialize(user)
      return unless user.admin?

      can :read, Order
      can :read, Trade
      can :read, Proof
      can :update, Proof
      can :manage, Document
      can :manage, Member
      can :manage, Ticket
      can :manage, IdDocument
      can :manage, TwoFactor

      can :menu, Deposit
      can :manage, ::Deposits::Bank
      can :manage, ::Deposits::Satoshi
      can :manage, ::Deposits::Litecoin
      can :manage, ::Deposits::Ether
      can :manage, ::Deposits::Bcash
      can :manage, ::Deposits::Usdt
      can :manage, ::Deposits::Monero
      can :manage, ::Deposits::Ripple
      can :manage, ::Deposits::Dash
      can :manage, ::Deposits::Neo
      can :manage, ::Deposits::Usdc

      can :menu, Withdraw
      can :manage, ::Withdraws::Bank
      can :manage, ::Withdraws::Satoshi
      can :manage, ::Withdraws::Litecoin
      can :manage, ::Withdraws::Ether
      can :manage, ::Withdraws::Bcash
      can :manage, ::Withdraws::Usdt
      can :manage, ::Withdraws::Monero
      can :manage, ::Withdraws::Ripple
      can :manage, ::Withdraws::Dash
      can :manage, ::Withdraws::Neo
      can :manage, ::Withdraws::Usdc
    end
  end
end
