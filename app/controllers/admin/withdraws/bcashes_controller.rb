module Admin
  module Withdraws
    class BcashesController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Bcash'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_bcashes = @bcashes.with_aasm_state(:accepted).order("id DESC")
        @all_bcashes = @bcashes.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @bcash.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @bcash.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
