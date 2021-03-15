module Admin
  class BotsController < BaseController
    load_and_authorize_resource

    def index
      @bots = Bot.all.page(params[:page]).per(10)
    end

    def create
      @bot = Bot.new(bot_params)
      @errors = @bot.errors.full_messages unless @bot.save
    end

    def update
      @errors = @bot.errors.full_messages unless @bot.update(bot_params)
    end

    def toggle
      @bot.disabled = !@bot.disabled?
      @bot.save
    end

    def destroy
      @bot.destroy
      redirect_to admin_bots_url, notice: 'Bot destroyed successfully.'
    end

    def restart
      @msg = `rake daemon:autobot:restart`
    end

    def kill_bot
      Bot.kill_daemon
    end

    protected

    def bot_params
      params.permit(:market_id, :start_sec, :end_sec, :start_sec_trade, :end_sec_trade, :best_price, :best_buy, :best_sell, :min_price, :max_price, :best_vol, :min_vol, :max_vol)
    end

  end
end
