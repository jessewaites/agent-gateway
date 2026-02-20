require "rails"
require "active_record/railtie"
require "action_controller/railtie"

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load = false
    config.secret_key_base = "test-secret-key-base-for-agent-gateway"
    config.root = File.expand_path("..", __dir__)
  end
end
