require 'httparty'

module TripleEyeEffable
  class DirectUploads
    # Includes
    include HTTParty

    attr_reader :api_key, :api_url

    def initialize(api_key: nil, api_url: nil)
      @api_key = api_key || TripleEyeEffable.config.api_key
      @api_url = api_url || TripleEyeEffable.config.url
    end

    def direct_upload(blob)
      self.class.post("#{api_url}/rails/active_storage/direct_uploads", body: { blob: }, headers:)
    end

    private

    def headers
      { 'X-API-KEY' => api_key }
    end

  end
end