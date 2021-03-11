module Admin
  module Withdraws
    class CitiusdsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Citiusd'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_citiusds = @citiusds.with_aasm_state(:accepted).order("id DESC")
        @all_citiusds = @citiusds.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @citiusd.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @citiusd.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
