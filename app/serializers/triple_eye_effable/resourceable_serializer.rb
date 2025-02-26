module TripleEyeEffable
  module ResourceableSerializer
    extend ActiveSupport::Concern

    included do
      index_attributes :content_type, :content_url, :content_download_url, :content_iiif_url, :content_inline_url,
                       :content_info_url, :content_preview_url, :content_thumbnail_url, :manifest_url
      show_attributes :content_type, :content_url, :content_download_url, :content_iiif_url, :content_inline_url,
                      :content_info_url, :content_preview_url, :content_thumbnail_url, :manifest_url
    end

  end
end
