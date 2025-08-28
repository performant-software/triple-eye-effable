class Configuration
  attr_accessor :api_key
  attr_accessor :url
  attr_accessor :project_id
  attr_accessor :base_controller

  def base_controller_class
    self.base_controller || 'ActionController::API'
  end
end
