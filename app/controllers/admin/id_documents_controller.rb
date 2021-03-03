module Admin
  class IdDocumentsController < BaseController
    load_and_authorize_resource

    def index
      @id_documents = @id_documents.order(:updated_at).reverse_order.page params[:page]
    end

    def show
    end

    def update
      @id_document.update_attribute('note', params[:id_document][:note]) rescue nil
      @id_document.aasm_state = params[:commit] == 'Approve' ? 'verified' : 'rejected'
      @id_document.save(validate: false)
      @id_document.send_status_email
      redirect_to admin_id_document_path(@id_document)
    end
  end
end
