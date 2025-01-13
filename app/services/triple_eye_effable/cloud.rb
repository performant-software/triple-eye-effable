require 'httparty'

module TripleEyeEffable
  class Cloud
    # Includes
    include HTTParty

    # HTTP response constants
    RESPONSE_KEYS = %i(
      content_url
      content_download_url
      content_iiif_url
      content_info_url
      content_inline_url
      content_preview_url
      content_thumbnail_url
      content_type
      manifest
      manifest_url
      uuid
    )

    def self.filename(name)
      name&.force_encoding(Encoding::ASCII_8BIT)
    end

    def initialize(api_key: nil, api_url: nil, project_id: nil, read_only: false)
      @api_key = api_key || TripleEyeEffable.config.api_key
      @api_url = api_url || TripleEyeEffable.config.url
      @project_id = project_id || TripleEyeEffable.config.project_id
      @read_only = read_only
    end

    def create_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      response = upload_resource(resourceable)
      add_error(resourceable, response) and return unless response.success?

      resource_id, data = parse_response(response)

      resourceable.resource_description = ResourceDescription.new(resource_id: resource_id, content_type: data[:content_type])
      load_description resourceable.resource_description
    end

    def delete_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      return if resourceable.resource_description.nil?

      id = resourceable.resource_description.resource_id
      response = self.class.delete("#{base_url}/#{id}", headers: headers)
      add_error(resourceable, response) unless response.success?
    end

    def download_resource(resourceable)
      return if resourceable.nil? || resourceable.resource_description.nil?

      resource_description = resourceable.resource_description
      response = get_resource(resource_description.resource_id)

      parse_response(response)
    end

    def get_resource(resource_id)
      self.class.get("#{base_url}/#{resource_id}", headers: headers)
    end

    def load_description(resource_description)
      id = resource_description.resource_id

      resource_description.assign_attributes(
        content_url: "#{base_url}/#{id}/content",
        content_download_url: "#{base_url}/#{id}/download",
        content_iiif_url: "#{base_url}/#{id}/iiif",
        content_info_url: "#{base_url}/#{id}/info",
        content_inline_url: "#{base_url}/#{id}/inline",
        content_preview_url: "#{base_url}/#{id}/preview",
        content_thumbnail_url: "#{base_url}/#{id}/thumbnail",
        manifest_url: "#{base_url}/#{id}/manifest"
      )
    end

    def update_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      resource_description = resourceable.resource_description
      id = resource_description.resource_id

      response = self.class.put("#{base_url}/#{id}", body: request_body(resourceable), headers: headers)
      add_error(resourceable, response) and return unless response.success?

      resource_id, data = parse_response(response)
      resource_description.content_type = data[:content_type]
      resource_description.save if resource_description.content_type_changed?

      load_description resource_description
    end

    def upload_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      self.class.post(base_url, body: request_body(resourceable), headers: headers)
    end

    private

    def add_error(resourceable, response)
      message = response['exception'] || response['message'] || response['errors']
      resourceable.errors.add(:base, message)
    end

    def base_url
      "#{@api_url}/public/resources"
    end

    def headers
      { 'X-API-KEY' => @api_key }
    end

    def parse_response(response)
      return [] unless response && response['resource'].present?

      data = response['resource'].symbolize_keys.slice(*RESPONSE_KEYS)
      [data[:uuid], data.except(:uuid)]
    end

    def request_body(resourceable)
      name = self.class.filename(resourceable.name) if resourceable.respond_to?(:name)
      content = resourceable.content if resourceable.respond_to?(:content)
      metadata = resourceable.metadata if resourceable.respond_to?(:metadata)

      body = {
        resource: {
          project_id: @project_id,
          name: name,
          metadata: metadata
        }
      }

      # Only send content if it's being changed
      if content.present?
        # handle unicode in original_filename
        content.original_filename = content.original_filename.force_encoding(Encoding::ASCII_8BIT)
        body[:resource][:content] = content
      end

      body
    end
  end
end
