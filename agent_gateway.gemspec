require_relative "lib/agent_gateway/version"

Gem::Specification.new do |spec|
  spec.name          = "agent_gateway"
  spec.version       = AgentGateway::VERSION
  spec.authors       = ["Jesse Waites"]
  spec.email         = ["jesse@example.com"]

  spec.summary       = "Rails engine exposing app data as a single AI-agent-friendly JSON endpoint"
  spec.description   = "A mountable Rails engine that provides a configured, authenticated JSON briefing endpoint for AI agents to consume app data."
  spec.homepage      = "https://github.com/jessewaites/agent_gateway"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "LICENSE", "README.md", "lando.jpeg"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
end
