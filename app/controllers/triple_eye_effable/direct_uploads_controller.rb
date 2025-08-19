module TripleEyeEffable
  class DirectUploadsController < ApplicationController
    # Actions
    before_action do |controller|
      next unless TripleEyeEffable.config.authenticate.present?
      controller.send(TripleEyeEffable.config.authenticate)
    end

    def create
      response = DirectUploads.new.direct_upload(direct_upload_params)
      render json: response, status: response.code
    end

    private

    def direct_upload_params
      params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, metadata: {})
    end

  end
end