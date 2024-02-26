require 'httparty'

module TripleEyeEffable
  class Presentation
    include HTTParty

    def initialize(api_key: nil, api_url: nil, project_id: nil)
      @api_key = api_key || TripleEyeEffable.config.api_key
      @api_url = api_url || TripleEyeEffable.config.url
      @project_id = project_id || TripleEyeEffable.config.project_id
    end

    def create_collection(id:, label:, items:)
      body = { id: id, label: label, items: items }
      self.class.post("#{base_url}/collection", headers: headers, body: body)
    end

    def create_manifest(id:, label:, resource_ids:)
      body = { id: id, label: label, resource_ids: resource_ids }
      self.class.post("#{base_url}/manifest", headers: headers, body: body)
    end

    private

    def base_url
      "#{@api_url}/public/presentation"
    end

    def headers
      { 'X-API-KEY' => @api_key }
    end
  end
end