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
      content_preview_url
      content_thumbnail_url
      content_type
      manifest
      uuid
    )

    def initialize
      @api_key = TripleEyeEffable.config.api_key
      @api_url = TripleEyeEffable.config.url
      @project_id = TripleEyeEffable.config.project_id
    end

    def create_resource(resourceable)
      response = self.class.post(base_url, body: request_body(resourceable), headers: headers)
      resource_id, = parse_response(response)
      create_description resourceable, resource_id
    end

    def delete_resource(resourceable)
      return if resourceable.resource_description.nil?

      id = resourceable.resource_description.resource_id
      self.class.delete("#{base_url}/#{id}", headers: headers)
    end

    def load_resource(resourceable)
      return if resourceable.resource_description.nil?

      resource_description = resourceable.resource_description
      response = self.class.get("#{base_url}/#{resource_description.resource_id}")
      resource_id, data = parse_response(response)

      data&.keys&.each do |key|
        next unless resource_description.respond_to?("#{key.to_s}=")
        resource_description.send("#{key.to_s}=", data[key])
      end
    end

    def update_resource(resourceable)
      id = resourceable.resource_description.resource_id
      self.class.put("#{base_url}/#{id}", body: request_body(resourceable), headers: headers)
    end

    private

    def base_url
      "#{@api_url}/public/resources"
    end

    def create_description(resourceable, resource_id)
      resourceable.resource_description = ResourceDescription.new(resource_id: resource_id)
    end

    def headers
      { 'X-API-KEY' => @api_key }
    end

    def parse_response(response)
      return nil unless response && response['resource'].present?

      data = response['resource'].symbolize_keys.slice(*RESPONSE_KEYS)
      [data[:uuid], data.except(:uuid)]
    end

    def request_body(resourceable)
      name = resourceable.name.force_encoding(Encoding::ASCII_8BIT) if resourceable.respond_to?(:name)
      content = resourceable.content if resourceable.respond_to?(:content)
      metadata = resourceable.metadata if resourceable.respond_to?(:metadata)

      body =       {
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
