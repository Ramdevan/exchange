class StakingsController < ApplicationController
	before_action :set_staking, only: [:get_staking,:staking_duration_info,:locked_type_option,:early_redeem, :redeem_now]
	before_action :set_staking_locked_duration, only: [:get_staking, :staking_duration_info]

	def index
		@locked_stakings = Staking.locked_stackings.today
		@defi_stakings = Staking.defi_stackings.today
	end

	def staking_duration_info
	end

	def get_staking
		@subscription = StakingLockedSubscription.new(staking_id: @staking.try(:id),staking_locked_duration_id: @staking_locked_duration.try(:id))
		@flexible = @staking_locked_duration.try(:flexible).present?
	end

	def confirm_staking_locked
		if current_user.present?
			@staking_locked = current_user.staking_locked_subscriptions.build(staking_locked_params)
			respond_to do |format|
	      if @staking_locked.save
	        format.js
	      else
	        format.js
	      end
	    end
		end
	end

	def locked_type_option
		@flexible = params[:flexible] == "true"
		@staking_locked_duration = @staking.staking_locked_durations.joins(:staking_duration).where("staking_durations.flexible = ?",@flexible).first
	end

	def early_redeem
		@subscription = @staking.current_locked_staking(current_user)
		@subscription.early_redeem
		staking_locked_duration
	end

	def redeem_now
		@subscription = @staking.current_locked_staking(current_user)
		@subscription.redeem_now
		staking_locked_duration
	end

	def staking_locked_duration
		@staking_locked = @subscription.staking_duration
	end

	private

	def set_staking_locked_duration
		@staking_locked_duration = StakingDuration.find_by(id: params[:staking_locked_duration_id])
	end

	def set_staking
		@staking = Staking.find_by(id: params[:id])
	end

	def staking_locked_params
		params.require(:staking_locked_subscription).permit(
			:staking_duration_id,
			:staking_id,
			:amount
		)
	end
end
