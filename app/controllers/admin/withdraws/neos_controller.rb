module Admin
    module Withdraws
        class NeosController < ::Admin::Withdraws::BaseController
            load_and_authorize_resource :class => '::Withdraws::Neo'
    
            def index
            start_at = DateTime.now.ago(60 * 60 * 24)
            @one_neos = @neos.with_aasm_state(:accepted).order("id DESC")
            @all_neos = @neos.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
            end
    
            def show
            end
    
            def update
            @neo.process!
            redirect_to :back, notice: t('.notice')
            end
    
            def destroy
            @neo.reject!
            redirect_to :back, notice: t('.notice')
            end
        end
    end
end
  