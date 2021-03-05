module Admin
  module Withdraws
    class BnbsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Bnb'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_bnbs = @bnbs.with_aasm_state(:accepted).order("id DESC")
        @all_bnbs = @bnbs.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @bnb.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @bnb.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
