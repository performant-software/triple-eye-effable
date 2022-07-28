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
