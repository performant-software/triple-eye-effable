module TripleEyeEffable
  module ResourceableController
    extend ActiveSupport::Concern

    included do
      preloads :resource_description
    end
  end
end