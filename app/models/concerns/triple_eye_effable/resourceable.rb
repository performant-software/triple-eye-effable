module TripleEyeEffable
  module Resourceable
    extend ActiveSupport::Concern

    included do
      # Relationships
      has_one :resource_description, as: :resourceable, dependent: :destroy, class_name: 'TripleEyeEffable::ResourceDescription'

      # Transient attributes
      attr_accessor :content

      # Delegates
      delegate :content_url, to: :resource_description, allow_nil: true
      delegate :content_download_url, to: :resource_description, allow_nil: true
      delegate :content_iiif_url, to: :resource_description, allow_nil: true
      delegate :content_inline_url, to: :resource_description, allow_nil: true
      delegate :content_preview_url, to: :resource_description, allow_nil: true
      delegate :content_thumbnail_url, to: :resource_description, allow_nil: true
      delegate :content_type, to: :resource_description, allow_nil: true
      delegate :manifest, to: :resource_description, allow_nil: true
      delegate :manifest_url, to: :resource_description, allow_nil: true

      # Callbacks
      after_find :load_resource
      before_create :create_resource
      before_destroy :delete_resource
      before_update :update_resource

      private

      def create_resource
        service = TripleEyeEffable::Cloud.new
        service.create_resource(self)

        throw(:abort) unless self.errors.empty?
      end

      def delete_resource
        service = TripleEyeEffable::Cloud.new
        service.delete_resource(self)

        throw(:abort) unless self.errors.empty?
      end

      def load_resource
        service = TripleEyeEffable::Cloud.new
        service.load_resource(self)

        throw(:abort) unless self.errors.empty?
      end

      def update_resource
        service = TripleEyeEffable::Cloud.new
        service.update_resource(self)

        throw(:abort) unless self.errors.empty?
      end
    end
  end
end
