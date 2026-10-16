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
      name&.dup&.force_encoding(Encoding::ASCII_8BIT)
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

    # Queues static asset generation on the IIIF Cloud instance for the passed resource IDs.
    # `base_url`/`destination` are forwarded as-is to IIIF Cloud's endpoint. IIIF Cloud currently
    # generates assets for the whole batch synchronously before responding, so this uses a long
    # timeout as a stopgap rather than the default ~60s.
    #
    # job_uuid is required so callers that split work into multiple batches (e.g.
    # core-data-cloud's GenerateStaticAssetsJob) can pass the same uuid on every call and have
    # IIIF Cloud accumulate them under one trackable Job; generate one with SecureRandom.uuid
    # before the first call. Poll completion with #job_status.
    #
    # storage is required - IIIF Cloud no longer has any environment-configured fallback and
    # will reject the request without it. It must include :bucket, :access_key_id, and
    # :secret_access_key, and may optionally include :session_token for short-lived credentials.
    # The storage endpoint/region are fixed server-side on IIIF Cloud and cannot be set here.
    def create_static_assets(resource_ids:, base_url:, destination:, job_uuid:, storage:)
      raise I18n.t('errors.read_only') if @read_only

      response = self.class.post(
        "#{@api_url}/public/resources/create_static_assets",
        body: {
          resource_ids: resource_ids,
          base_url: base_url,
          destination: destination,
          job_uuid: job_uuid,
          storage: storage
        }.to_json,
        headers: headers.merge('Content-Type' => 'application/json'),
        timeout: 600
      )

      return response if response.success?
      raise "IIIF Cloud request failed (#{response.code}): #{response.body}"
    end

    def get_resource(resource_id)
      self.class.get("#{base_url}/#{resource_id}", headers: headers)
    end

    # Fetches the current status of a Job (e.g. one returned by #create_static_assets) as a
    # symbolized hash: { status:, total_count:, completed_count:, failed_count: }. Raises on any
    # non-success response (including a 404 for an unknown uuid) - callers polling for completion
    # should treat a raised error as "not done yet" up to their own retry/attempt limit.
    def job_status(uuid)
      response = self.class.get("#{@api_url}/public/jobs/#{uuid}", headers: headers)

      raise "IIIF Cloud request failed (#{response.code}): #{response.body}" unless response.success?

      response.parsed_response.symbolize_keys
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

    def save_resource(resourceable)
      if resourceable.resource_description.present?
        update_resource resourceable
      else
        create_resource resourceable
      end
    end

    def update_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      resource_description = resourceable.resource_description
      id = resource_description.resource_id

      response = self.class.put("#{base_url}/#{id}", body: request_body(resourceable), headers: headers, multipart: true)
      add_error(resourceable, response) and return unless response.success?

      resource_id, data = parse_response(response)
      resource_description.content_type = data[:content_type]
      resource_description.save if resource_description.content_type_changed?

      load_description resource_description
    end

    def upload_resource(resourceable)
      raise I18n.t('errors.read_only') if @read_only

      self.class.post(base_url, body: request_body(resourceable), headers: headers, multipart: true)
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
      name = resourceable.name if resourceable.respond_to?(:name)
      content = resourceable.content if resourceable.respond_to?(:content)
      metadata = resourceable.metadata if resourceable.respond_to?(:metadata)
      storage_key = resourceable.storage_key if resourceable.respond_to?(:storage_key)

      body = {
        resource: {
          project_id: @project_id,
          name:,
          metadata:,
          storage_key:
        }
      }

      # Only send content if it's being changed
      if content.present?
        # Handle unicode in original_filename
        if content.respond_to?(:original_filename)
          content.original_filename = self.class.filename(content.original_filename)
        end

        # Append the content to the body
        body[:resource][:content] = content
      end

      body
    end
  end
end
