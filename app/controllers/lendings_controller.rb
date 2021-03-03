class LendingsController < ApplicationController
	before_filter :auth_member!
	before_action :set_lending, only: %i[flexible_transfer flexible_lending auto_transfer locked_transfer]
	before_action :set_flexible_subscription, only: %i[fast_redeem standard_redeem]

	def index
		@flexible_lendings = Lending.flexible.today
		@locked_lendings = Lending.locked.today
		@activity_lendings = Lending.activities.today
	end

	def flexible_transfer
	end

	def create_flexible_subscription
		@fs = current_user.lending_subscriptions.build(lending_sub_params)
  
    respond_to do |format|
      if @fs.save
        format.js 
      else
        format.js
      end
    end
	end

	def create_locked_subscription
		@ls = current_user.lending_subscriptions.build(lending_sub_params)
  
    respond_to do |format|
      if @ls.save
        format.js 
      else
        format.js
      end
    end
	end

	def locked_transfer
	end

	def activity_transfer
		@al = Lending.find_by(id: params[:id])
	end

	def create_activity_subscription
		@as = current_user.lending_subscriptions.build(lending_sub_params)
  
    respond_to do |format|
      if @as.save
        format.js 
      else
        format.js
      end
    end
	end

	def auto_transfer
		if @fl.present? && @fl.auto_tansfer(current_user).present?
			@fl.auto_tansfer(current_user).destroy
			@fl.unlock_auto_tansfer(current_user)
			render nothing: true
		end
	end

	def create_auto_tansfer
		@at = current_user.lending_auto_transfers.build(auto_transfer_params)
  
    respond_to do |format|
      if @at.save
        format.js 
      else
        format.js
      end
    end
	end

	def fast_redeem
		@fs.update_flexible_redeem(true, t('redeem_lendings.fast'))
		redirect_to :back
	end

	def standard_redeem
		@fs.update_flexible_redeem(false, t('redeem_lendings.standard'))
		redirect_to :back
	end

	private

	def set_lending
		@fl = Lending.find_by(id: params[:id])
	end

	def lending_sub_params
		params.require(:lending_subscriptions).permit(
			:lending_id,
			:amount,
			:subscription_date,
			:lending_duration_id,
			:interest_amount,
			:is_auto_transfer,
			:is_completed,
			:is_auto_renew,
			:start_date,
			:end_date
		)
	end

	def auto_transfer_params
		params.require(:lending_auto_transfers).permit(
			:currency,
			:is_auto_transfer,
			:lending_id
		)
	end

	def set_flexible_subscription
		@fs = LendingSubscription.find_by(id: params[:id])
	end
end
