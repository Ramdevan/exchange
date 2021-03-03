module Concerns
  module OrderCreation
    extend ActiveSupport::Concern

    def order_params(order)
      params[order][:bid] = params[:bid]
      params[order][:ask] = params[:ask]
      params[order][:state] = Order::WAIT
      params[order][:currency] = params[:market]
      params[order][:member_id] = current_user.id
      params[order][:volume] = params[order][:origin_volume]
      params[order][:source] = 'Web'
      if params[order][:ord_type] == 'stop_limit' || params[order][:ord_type] == 'stop_loss'
        if params[order][:stop_price].to_d >= Global[params[:market]].ticker[:last]
          params[order][:trigger_cond] = :above
        else
          params[order][:trigger_cond] = :below
        end
      end

      params.require(order).permit(
        :bid, :ask, :currency, :price, :stop_price, :trigger_cond, :source,
        :state, :origin_volume, :volume, :member_id, :ord_type)
    end

    def order_submit
      begin
        Ordering.new(@order).submit
        render status: 200, json: success_result
      rescue => e
        ExceptionNotifier.notify_exception(e, env: request.env)
        Rails.logger.warn "Member id=#{@order.member_id} failed to submit order: #{$!}"
        Rails.logger.warn params.inspect
        Rails.logger.warn $!.backtrace[0,20].join("\n")
        render status: 500, json: error_result(@order.errors)
      end
    end

    def success_result
      Jbuilder.encode do |json|
        json.result true
        json.message I18n.t("private.markets.show.success")
        json.notice I18n.t("private.markets.show.order_creation_success")
      end
    end

    def error_result(args)
      Jbuilder.encode do |json|
        json.result false
        json.message I18n.t("private.markets.show.error")
        json.errors args
      end
    end
  end
end
