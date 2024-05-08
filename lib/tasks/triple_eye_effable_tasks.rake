require 'httparty'
require 'optparse'

namespace :triple_eye_effable do
  desc 'Sets the content_type attribute on each resource record'
  task :set_content_type => :environment do
    service = TripleEyeEffable::Cloud.new(read_only: true)

    # Build the list of classes that include the Resourceable concern
    classes = []

    Rails.application.eager_load! if Rails.env.development?

    ActiveRecord::Base.descendants.each do |model|
      next unless model.include?(TripleEyeEffable::Resourceable)
      classes << model
    end

    classes.each do |klass|
      query = klass
                .joins(:resource_description)
                .preload(:resource_description)
                .where(resource_description: { content_type: nil })

      query.find_each do |resourceable|
        resource_id, data = service.download_resource(resourceable)
        content_type = data[:content_type]

        next if content_type.nil?

        resource_description = resourceable.resource_description
        resource_description.update_attribute(:content_type, content_type)
      end
    end
  end

  desc 'Transfer resources from one IIIF Cloud instance to another.'
  task :transfer_resources => :environment do
    # Parse the arguments
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake triple_eye_effable:transfer_resources [options]'

      opts.on('--api-key api_key', 'IIIF Cloud API Key') do |api_key|
        options[:api_key] = api_key
      end

      opts.on('--api-url api_url', 'IIIF Cloud API URL') do |api_url|
        options[:api_url] = api_url
      end

      opts.on('--project-id project_id', 'IIIF Cloud Project ID') do |project_id|
        options[:project_id] = project_id
      end
    end

    args = opt_parser.order!(ARGV) {}
    opt_parser.parse!(args)

    if options[:api_key].blank?
      puts 'Please specify an API key...'
      exit 0
    end

    if options[:api_url].blank?
      puts 'Please specify an API URL...'
      exit 0
    end

    if options[:project_id].blank?
      puts 'Please specify a project ID...'
      exit 0
    end

    # Build the list of classes that include the Resourceable concern
    classes = []

    Rails.application.eager_load! if Rails.env.development?

    ActiveRecord::Base.descendants.each do |model|
      next unless model.include?(TripleEyeEffable::Resourceable)
      classes << model
    end

    source_service = TripleEyeEffable::Cloud.new(
      api_key: options[:api_key],
      api_url: options[:api_url],
      project_id: options[:project_id],
      read_only: true
    )

    destination_service = TripleEyeEffable::Cloud.new

    classes.each do |klass|
      count = klass.count

      klass.find_each.with_index do |resourceable, index|
        # Load the resource from the source application
        source_service.load_resource(resourceable)

        # Download the binary content
        resourceable.content = download_content(resourceable)

        # Upload the resource to the destination application
        response = destination_service.upload_resource(resourceable)

        # Set the new resource ID on the resource_description
        resource_id = response['resource']['uuid']
        resourceable.resource_description.update(resource_id: resource_id)

        # Log the progress
        log_progress(klass, index, count)
      end

      log_progress(klass, count, count, true)
    end
  end

  # Downloads the content for the passed resourceable record
  def download_content(resourceable)
    begin
      response = HTTParty.get(resourceable.content_url)

      file = Tempfile.new
      file.binmode
      file.write(response.body)
      file.rewind

      content = ActionDispatch::Http::UploadedFile.new(
        tempfile: file,
        type: resourceable.content_type,
        filename: TripleEyeEffable::Cloud.filename(resourceable.name)
      )
    rescue
      puts "Error downloading file #{resourceable.id}"
      content = nil
    end

    content
  end

  # Logs the progress for the passed class
  def log_progress(klass, index, count, force = false)
    return unless force || index + 1 % count != 10

    puts "#{klass.to_s}: Uploaded #{index + 1} out of #{count} records..."
  end
end
