AgentGateway::Engine.routes.draw do
  get ":path_secret/briefing", to: "briefings#show"
end
