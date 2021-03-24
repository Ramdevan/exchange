module Admin
    module Withdraws
      class EnjsController < ::Admin::Withdraws::BaseController
        load_and_authorize_resource :class => '::Withdraws::Enj'
  
        def index
          start_at = DateTime.now.ago(60 * 60 * 24)
          @one_enjs = @enjs.with_aasm_state(:accepted).order("id DESC")
          @all_enjs = @enjs.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
        end
  
        def show
        end
  
        def update
          @enj.process!
          redirect_to :back, notice: t('.notice')
        end
  
        def destroy
          @enj.reject!
          redirect_to :back, notice: t('.notice')
        end
      end
    end
  end
  