module TripleEyeEffable
  class ResourceDescription < ApplicationRecord
    # Transient attributes
    attr_accessor :content_url
    attr_accessor :content_download_url
    attr_accessor :content_iiif_url
    attr_accessor :content_preview_url
    attr_accessor :content_thumbnail_url
    attr_accessor :content_type
    attr_accessor :manifest

    # Validations
    validates :resource_id, presence: true
  end
end
