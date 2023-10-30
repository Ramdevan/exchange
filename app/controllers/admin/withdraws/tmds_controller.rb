module Admin
  module Withdraws
    class TmdsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Tmd'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_tmds = @tmds.with_aasm_state(:accepted).order("id DESC")
        @all_tmds = @tmds.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @tmd.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @tmd.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
