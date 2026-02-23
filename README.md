![Agent Gateway](lando.jpeg)

# Agent Gateway

> **OpenClaw users:** Use the [Ruby on Rails Gateway](https://clawhub.ai/jessewaites/ruby-on-rails-gateway) skill alongside this gem for easy and fast setup.


Agent Gateway is a mountable Rails engine that gives AI agents secure, authenticated access to your Rails app’s allow-listed data through a single read-only JSON endpoint.

Ask questions about your business in plain English and get real answers from OpenClaw, Claude Code, Codex, and other AI tools.

Schedule automated daily, weekly, or monthly reports across all your Rails apps and turn your data into ongoing conversations.

“How many new users did we get last week?” Just ask your AI.
“What was our revenue last month across all our apps?” Just ask your AI.

## Installation

Add to your Gemfile:

```ruby
gem "agent_gateway"
```

Then mount the engine in `config/routes.rb`:

```ruby
mount AgentGateway::Engine => "/agent-gateway"
```

## Generating Credentials

```bash
# Generate a secure auth token
ruby -e 'require "securerandom"; puts SecureRandom.hex(32)'

# Generate a path secret
ruby -e 'require "securerandom"; puts SecureRandom.uuid'
```

Set them as environment variables:

```bash
# .env (local development)
AGENT_GATEWAY_TOKEN=<generated hex>
AGENT_GATEWAY_SECRET=<generated uuid>

# Heroku
heroku config:set AGENT_GATEWAY_TOKEN=<generated hex> AGENT_GATEWAY_SECRET=<generated uuid>
```

## Configuration

Create an initializer `config/initializers/agent_gateway.rb`:

```ruby
# Guard against missing env vars during build steps (see note below)
return unless ENV["AGENT_GATEWAY_TOKEN"].present?

AgentGateway.configure do |c|
  c.app_name    = "MyApp"
  c.auth_token  = ENV["AGENT_GATEWAY_TOKEN"]  # required — raises at boot if blank
  c.path_secret = ENV["AGENT_GATEWAY_SECRET"] # auto-generated + logged if omitted
  c.default_period = "7d"                     # 1d, 7d, 30d, 90d, 1y, all

  c.expose :users, model: "User" do
    count
    latest 5
    attributes :email, :name, :created_at
    scope :active
    date_column :created_at
  end

  c.expose :orders, model: "Order" do
    count
    sum :total
    avg :total
    latest 3
    attributes :id, :total, :status, :created_at
  end
end
```

> **Heroku / build-phase note:** Platforms like Heroku don't expose config vars during the build phase. Without the `return unless` guard, the engine raises on `rake assets:precompile` and the deploy fails. The guard skips configuration when the token isn't available (build time) and configures normally at runtime.

### DSL Reference

| Method                    | Description                                                     |
| ------------------------- | --------------------------------------------------------------- |
| `count`                   | Include record count                                            |
| `latest N`                | Include N most recent records                                   |
| `attributes :col1, :col2` | Allowlist fields on latest records                              |
| `sum :column`             | Sum a numeric column (call multiple times for multiple columns) |
| `avg :column`             | Average a numeric column (call multiple times)                  |
| `scope :name`             | Apply a named scope to all queries                              |
| `date_column :name`       | Column used for period filtering (default: `created_at`)        |

## Endpoint

```
GET /<mount_path>/<path_secret>/briefing
```

### Authentication

Two-layer auth:

1. **Path secret** — wrong value returns `404` (endpoint appears nonexistent)
2. **Bearer token** — wrong/missing value returns `401`

```bash
curl -H "Authorization: Bearer $TOKEN" \
  https://myapp.com/agent-gateway/$SECRET/briefing
```

### Query Parameters

| Param       | Description                                        | Example                   |
| ----------- | -------------------------------------------------- | ------------------------- |
| `period`    | Time window: `1d`, `7d`, `30d`, `90d`, `1y`, `all` | `?period=30d`             |
| `resources` | Comma-separated resource keys to include           | `?resources=users,orders` |
| `latest`    | Override latest count for all resources            | `?latest=10`              |

### Response

```json
{
  "app_name": "MyApp",
  "generated_at": "2026-02-20T12:00:00Z",
  "period": {
    "from": "2026-02-13",
    "to": "2026-02-20",
    "days": 7
  },
  "data": {
    "users": {
      "count": 142,
      "latest": [
        {
          "email": "new@example.com",
          "name": "New User",
          "created_at": "2026-02-20"
        }
      ]
    },
    "orders": {
      "count": 89,
      "sum": { "total": 12450.0 },
      "avg": { "total": 139.89 },
      "latest": [
        {
          "id": 501,
          "total": "250.00",
          "status": "paid",
          "created_at": "2026-02-20"
        }
      ]
    }
  }
}
```

## Security Notes

- `path_secret` is compared using `ActiveSupport::SecurityUtils.secure_compare` (timing-safe)
- Bearer token is also compared with `secure_compare`
- If no `path_secret` is configured, one is auto-generated and printed to STDOUT at boot
- Missing `auth_token` raises at boot — the engine won't start without one

## Using with AI Agents

Point your AI agent at the briefing endpoint with the bearer token. The response is a single JSON payload designed for LLM consumption — structured, filterable, and concise.

Example system prompt snippet:

```
Fetch app data from: GET https://myapp.com/agent-gateway/<secret>/briefing
Header: Authorization: Bearer <token>
```

## License

MIT
