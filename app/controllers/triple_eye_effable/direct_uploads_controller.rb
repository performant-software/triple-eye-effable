module TripleEyeEffable
  class DirectUploadsController < ApplicationController
    # Actions
    before_action :set_metadata, only: :create

    def create
      response = DirectUploads.new.direct_upload(direct_upload_params)
      render json: response, status: response.code
    end

    private

    def direct_upload_params
      params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {})
    end

    def set_metadata
      return unless request.headers['X-STORAGE-KEY'].present?

      params[:blob][:metadata] ||= {}
      params[:blob][:metadata][:storage_key] = request.headers['X-STORAGE-KEY']
    end

  end
end