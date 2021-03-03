module Private
  class IdDocumentsController < BaseController

    def edit
      @id_document = current_user.id_document || current_user.create_id_document
    end

    def update
      @id_document = current_user.id_document

      if @id_document.update_attributes id_document_params
        @id_document.submit! if @id_document.unverified? || @id_document.rejected?

        redirect_to settings_path, notice: t('.notice.verification_submitted')
      else
        flash[:alert] = @id_document.errors.full_messages.join(', ')
        render :edit
      end
    end

    private

    def id_document_params
      params.require(:id_document).permit(:name, :birth_date, :address, :city, :country, :zipcode,
                                          :id_document_type, :id_document_number, :id_bill_type,
                                          {id_document_file_attributes: [:id, :file]},
                                          {id_bill_file_attributes: [:id, :file]})
    end
  end
end
