require "spec_helper"

RSpec.describe AgentGateway::Configuration do
  describe "defaults" do
    before { AgentGateway.reset_configuration! }

    it "sets app_name to 'App'" do
      expect(AgentGateway.configuration.app_name).to eq("App")
    end

    it "sets default_period to '7d'" do
      expect(AgentGateway.configuration.default_period).to eq("7d")
    end

    it "sets resources to an empty hash" do
      expect(AgentGateway.configuration.resources).to eq({})
    end

    it "sets path_secret to nil" do
      expect(AgentGateway.configuration.path_secret).to be_nil
    end

    it "sets auth_token to nil" do
      expect(AgentGateway.configuration.auth_token).to be_nil
    end
  end

  describe "#expose" do
    it "registers a resource with a block" do
      AgentGateway.configure do |c|
        c.expose(:users) do
          attributes :name, :email
          count
        end
      end

      resource = AgentGateway.configuration.resources[:users]
      expect(resource).to be_a(AgentGateway::ResourceConfig)
      expect(resource.attributes_list).to eq(%w[name email])
      expect(resource.count_enabled?).to be true
    end

    it "infers model name from key" do
      AgentGateway.configure do |c|
        c.expose(:users) {}
      end

      expect(AgentGateway.configuration.resources[:users].model_name).to eq("User")
    end

    it "accepts explicit model: option" do
      AgentGateway.configure do |c|
        c.expose(:customers, model: "Account") {}
      end

      expect(AgentGateway.configuration.resources[:customers].model_name).to eq("Account")
    end
  end

  describe ".reset_configuration!" do
    it "returns config to defaults" do
      AgentGateway.configure do |c|
        c.auth_token = "secret"
        c.app_name = "Custom"
        c.path_secret = "path"
        c.expose(:orders) { count }
      end

      AgentGateway.reset_configuration!

      config = AgentGateway.configuration
      expect(config.app_name).to eq("App")
      expect(config.auth_token).to be_nil
      expect(config.path_secret).to be_nil
      expect(config.resources).to eq({})
      expect(config.default_period).to eq("7d")
    end
  end

  describe "setting and reading attributes" do
    it "sets and reads auth_token" do
      AgentGateway.configure { |c| c.auth_token = "my-token" }
      expect(AgentGateway.configuration.auth_token).to eq("my-token")
    end

    it "sets and reads app_name" do
      AgentGateway.configure { |c| c.app_name = "MyApp" }
      expect(AgentGateway.configuration.app_name).to eq("MyApp")
    end

    it "sets and reads path_secret" do
      AgentGateway.configure { |c| c.path_secret = "s3cret" }
      expect(AgentGateway.configuration.path_secret).to eq("s3cret")
    end
  end
end
