module Admin
  class LendingsController < BaseController

  	def index
  		@flexible_lendings = Lending.flexible.before_today.order('published_on DESC')
			@locked_lendings = Lending.locked.before_today.order('published_on DESC')
			@activity_lendings = Lending.activities.before_today.order('published_on DESC')
  	end

  	def types
  		@types = LendingType.all.order('id DESC')
  	end

  	def save_types
  		@type = LendingType.new(type_params)

  		respond_to do |format|
	      if @type.save
	        format.js 
	      else
	        format.js
	      end
	    end
  	end

  	def durations
  		@durations = LendingDuration.all.group_by(&:currency)
  	end

  	def save_durations
  		@duration = LendingDuration.new(duration_params)

  		respond_to do |format|
	      if @duration.save
	        format.js 
	      else
	        format.js
	      end
	    end
  	end

  	def save_lending
  		@lending = Lending.new(lending_params)

  		respond_to do |format|
	      if @lending.save
	        format.js 
	      else
	        format.js
	      end
	    end
  	end

  	private

  	def type_params
  		params.require(:lending_types).permit(:name)
  	end

  	def duration_params
  		params.require(:lending_durations).permit(
  			:currency,
  			:duration_days,
  			:interest_rate
  		)
  	end

  	def lending_params
  		params.require(:lendings).permit(
  			:currency,
  			:today_apy,
  			:yesterday_apy,
  			:max_subscription_amount,
  			:lot_size,
  			:max_lot_size,
  			:lending_type_id,
  			:interest_rate,
  			:duration_days,
        :published_on
  		)
  	end
  end
end
