class Asset < ActiveRecord::Base
  belongs_to :attachable, polymorphic: true

  mount_uploader :file, FileUploader

  validates_presence_of :file
  validate :image_size_validation

  def image?
    file.content_type.start_with?('image') if file?
  end

  private

  def image_size_validation
    errors[:file] << "should be less than 10 MB" if file.size > 10.megabytes.to_i
  end
end

class Asset::IdDocumentFile < Asset
  def document_type
    attachable.id_document_type
  end
end

class Asset::IdBillFile < Asset
  def document_type
    attachable.id_bill_type
  end
end