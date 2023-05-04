module Admin
  module Withdraws
    class BusdsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Busd'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_busds = @busds.with_aasm_state(:accepted).order("id DESC")
        @all_busds = @busds.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @busd.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @busd.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
