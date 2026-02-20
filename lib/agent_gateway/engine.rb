module AgentGateway
  class Engine < ::Rails::Engine
    isolate_namespace AgentGateway

    config.after_initialize do
      cfg = AgentGateway.configuration

      if cfg.auth_token.nil? || cfg.auth_token.to_s.strip.empty?
        raise "AgentGateway: auth_token must be configured. Set it via AgentGateway.configure { |c| c.auth_token = 'your-token' }"
      end

      if cfg.path_secret.nil? || cfg.path_secret.to_s.strip.empty?
        cfg.path_secret = SecureRandom.uuid
        puts "[AgentGateway] path_secret auto-generated: #{cfg.path_secret}"
      end
    end
  end
end
