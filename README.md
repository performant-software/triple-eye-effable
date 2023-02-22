# Triple Eye Effable
TODO: Comment me

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'triple_eye_effable', git: 'https://github.com/performant-software/triple-eye-effable.git', tag: 'v0.1.0'
```

And then execute:
```bash
$ bundle install
```

Or install it yourself as:
```bash
$ gem install triple_eye_effable
```

Execute the follow to copy the necessary migrations into your application.

```bash
$ bundle exec rails triple_eye_effable:install:migrations
```

Run the migrations.

```bash
$ bundle exec rake db:migrate
```

## Configuration

Add the following to `config/initializers/triple_eye_effable.rb`:

```ruby
TripleEyeEffable.configure do |config|
  config.api_key = ENV['IIIF_CLOUD_API_KEY']
  config.url = ENV['IIIF_CLOUD_URL']
  config.project_id = ENV['IIIF_CLOUD_PROJECT_ID']
end

```

## Resource Transfer

The `triple-eye-effable` gem comes packages with a rake task to assist with managing data. Let's say you want to pull a backup of your application's staging or production environment locally to test. You can easily restore the database, however all of the IIIF resources are still on the staging or production IIIF Cloud instance.

The following rake task will allow for "pulling" the resources and uploading them to another IIIF Cloud instance (either hosted locally, or somewhere else):

```shell
bundle exec rake triple_eye_effable:transfer_resources -- --api-key <YOUR_API_KEY> --api-url <SOURCE_IIIF_CLOUD_URL> --project-id <YOUR_PROJECT_ID>
```
