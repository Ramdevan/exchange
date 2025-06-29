module Admin
  module Withdraws
    class TmcsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Tmc'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_tmcs = @tmcs.with_aasm_state(:accepted).order("id DESC")
        @all_tmcs = @tmcs.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @tmc.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @tmc.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
