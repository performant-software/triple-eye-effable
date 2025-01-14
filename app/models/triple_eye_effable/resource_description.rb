module TripleEyeEffable
  class ResourceDescription < ApplicationRecord
    # Relationships
    belongs_to :resourceable, polymorphic: true

    # Transient attributes
    attr_accessor :content_url
    attr_accessor :content_download_url
    attr_accessor :content_iiif_url
    attr_accessor :content_info_url
    attr_accessor :content_inline_url
    attr_accessor :content_preview_url
    attr_accessor :content_thumbnail_url
    attr_accessor :manifest_url

    # Callbacks
    after_initialize :load_description

    # Validations
    validates :resource_id, presence: true

    private

    def load_description
      service = TripleEyeEffable::Cloud.new
      service.load_description(self)

      throw(:abort) unless self.errors.empty?
    end
  end
end
