module Admin
    module Withdraws
      class ManasController < ::Admin::Withdraws::BaseController
        load_and_authorize_resource :class => '::Withdraws::Mana'
  
        def index
          start_at = DateTime.now.ago(60 * 60 * 24)
          @one_manas = @manas.with_aasm_state(:accepted).order("id DESC")
          @all_manas = @manas.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
        end
  
        def show
        end
  
        def update
          @mana.process!
          redirect_to :back, notice: t('.notice')
        end
  
        def destroy
          @mana.reject!
          redirect_to :back, notice: t('.notice')
        end
      end
    end
  end
  