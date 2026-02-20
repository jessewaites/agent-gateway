Rails.application.routes.draw do
  mount AgentGateway::Engine => "/agent-gateway"
end
