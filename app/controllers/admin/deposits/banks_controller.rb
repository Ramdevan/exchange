module Admin
  module Deposits
    class BanksController < ::Admin::Deposits::BaseController
      load_and_authorize_resource :class => '::Deposits::Bank'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @oneday_banks = @banks.includes(:member).
          where('created_at > ?', start_at).
          order('id DESC')

        @available_banks = @banks.includes(:member).
          with_aasm_state(:submitting, :warning, :submitted).
          order('id DESC')

        @available_banks -= @oneday_banks
      end

      def show
        flash.now[:notice] = t('.notice') if @bank.aasm_state.accepted?
      end

      def update
        if params[:commit] == 'Accept'
          update_amount
        elsif params[:commit] == 'Reject'
          @bank.submit!
          @bank.reject!
          @bank.touch(:done_at)
          redirect_to :back
        else
          flash[:alert] = t('.error')
          redirect_to :back
        end
      end

      def update_amount
        if target_params[:txid].blank? || target_params[:amount].blank?
          flash[:alert] = target_params[:txid].blank? ? t('.blank_txid') : t('.blank_amount')
          redirect_to :back and return
        end

        if target_params[:amount].to_f <= 0.0
          flash[:alert] = t('.blank_amount')
          redirect_to :back and return
        end

        @bank.charge!(target_params[:txid])
        redirect_to :back
      end

      private
      def target_params
        params.require(:deposits_bank).permit(:sn, :holder, :amount, :created_at, :txid)
      end
    end
  end
end

