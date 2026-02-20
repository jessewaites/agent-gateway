ENV["RAILS_ENV"] = "test"

# Load Rails via the dummy app before agent_gateway (engine needs ::Rails)
require_relative "dummy/config/application"

require "agent_gateway"

# Configure AgentGateway before Rails initializes
AgentGateway.configure do |c|
  c.auth_token = "test-token"
  c.path_secret = "test-secret"
end

require_relative "dummy/config/environment"

require "rspec/rails"

# Load schema
ActiveRecord::Schema.verbose = false
load File.expand_path("dummy/db/schema.rb", __dir__)

RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.before(:each) do
    AgentGateway.reset_configuration!
    AgentGateway.configure do |c|
      c.auth_token = "test-token"
      c.path_secret = "test-secret"
      c.app_name = "TestApp"
    end
  end
end
