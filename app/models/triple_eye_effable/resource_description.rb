module TripleEyeEffable
  class ResourceDescription < ApplicationRecord
    # Transient attributes
    attr_accessor :content_url
    attr_accessor :content_download_url
    attr_accessor :content_iiif_url
    attr_accessor :content_preview_url
    attr_accessor :content_thumbnail_url

    # Validations
    validates :resource_id, presence: true
  end
end
