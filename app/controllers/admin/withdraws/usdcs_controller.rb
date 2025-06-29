module Admin
  module Withdraws
    class UsdcsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Usdc'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_usdcs = @usdcs.with_aasm_state(:accepted).order("id DESC")
        @all_usdcs = @usdcs.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @usdc.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @usdc.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
