module AgentGateway
  class Configuration
    attr_accessor :app_name, :path_secret, :auth_token, :default_period
    attr_reader :resources

    def initialize
      @app_name = "App"
      @path_secret = nil
      @auth_token = nil
      @default_period = "7d"
      @resources = {}
    end

    def expose(key, model: nil, &block)
      model_name = model || key.to_s.classify
      config = ResourceConfig.new(model_name)
      config.instance_eval(&block) if block
      @resources[key.to_sym] = config
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
