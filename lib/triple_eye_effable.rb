require 'triple_eye_effable/version'
require 'triple_eye_effable/engine'
require 'triple_eye_effable/configuration'

module TripleEyeEffable
  mattr_accessor :config, default: Configuration.new

  def self.configure(&block)
    block.call self.config
  end
end
