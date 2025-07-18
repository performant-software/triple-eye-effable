require_relative 'lib/triple_eye_effable/version'

Gem::Specification.new do |spec|
  spec.name        = 'triple_eye_effable'
  spec.version     = TripleEyeEffable::VERSION
  spec.authors     = ['Performant Software Solutions']
  spec.email       = ['derek@performantsoftware.com']
  spec.homepage    = 'https://github.com/performant-software/triple-eye-effable'
  spec.summary     = 'Serve your image resources via IIIF'
  spec.description = 'An engine used for integration with the IIIF Cloud platform'
  spec.license     = 'MIT'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '>= 6.0.3.2', '< 9'
  spec.add_dependency 'httparty', '~> 0.20.0'
end
