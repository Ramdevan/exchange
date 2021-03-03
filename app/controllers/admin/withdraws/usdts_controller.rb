module Admin
  module Withdraws
    class UsdtsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Usdt'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_usdts = @usdts.with_aasm_state(:accepted).order("id DESC")
        @all_usdts = @usdts.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @usdt.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @usdt.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
