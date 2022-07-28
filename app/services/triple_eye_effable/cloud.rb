module TripleEyeEffable
  class Cloud

    def initialize
      @api_key = TripleEyeEffable.config.api_key
      @api_url = TripleEyeEffable.config.url
      @project_id = TripleEyeEffable.config.project_id
    end

    def create_resource(resourceable)
      response = HTTParty.post(base_url, body: request_body(resourceable), headers: headers)
      resource_id, = parse_response(response)
      create_description resourceable, resource_id
    end

    def delete_resource(resourceable)
      id = resourceable.resource_description.resource_id
      HTTParty.delete("#{base_url}/#{id}", headers: headers)
    end

    def load_resource(resourceable)
      return if resourceable.resource_description.nil?

      resource_description = resourceable.resource_description
      response = HTTParty.get("#{base_url}/#{resource_description.resource_id}")
      resource_id, data = parse_response(response)

      data&.keys.each do |key|
        next unless resource_description.respond_to?("#{key.to_s}=")
        resource_description.send("#{key.to_s}=", data[key])
      end
    end

    def update_resource(resourceable)
      id = resourceable.resource_description.resource_id
      HTTParty.put("#{base_url}/#{id}", body: request_body(resourceable), headers: headers)
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
      data = response['resource']
               .symbolize_keys
               .slice(
                 :content_url,
                 :content_download_url,
                 :content_iiif_url,
                 :content_preview_url,
                 :content_thumbnail_url,
                 :uuid
               )

      [data[:uuid], data.except(:uuid)]
    end

    def request_body(resourceable)
      name = resourceable.name if resourceable.respond_to?(:name)
      content = resourceable.content if resourceable.respond_to?(:content)
      metadata = resourceable.metadata if resourceable.respond_to?(:metadata)

      {
        resource: {
          project_id: @project_id,
          name: name,
          content: content,
          metadata: metadata
        }
      }
    end
  end
end
