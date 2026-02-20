module AgentGateway
  class BriefingsController < ActionController::API
    before_action :verify_path_secret
    before_action :authenticate_token

    def show
      resources = build_resources
      period_info = build_period_info

      render json: {
        app_name: AgentGateway.configuration.app_name,
        generated_at: Time.current.iso8601,
        period: period_info,
        data: resources
      }
    end

    private

    def verify_path_secret
      unless ActiveSupport::SecurityUtils.secure_compare(
        params[:path_secret].to_s,
        AgentGateway.configuration.path_secret.to_s
      )
        head :not_found
      end
    end

    def authenticate_token
      token = request.headers["Authorization"].to_s.sub(/\ABearer\s+/, "")
      unless ActiveSupport::SecurityUtils.secure_compare(token, AgentGateway.configuration.auth_token.to_s)
        head :unauthorized
      end
    end

    def build_resources
      configs = AgentGateway.configuration.resources
      requested = params[:resources]&.split(",")&.map(&:strip)&.map(&:to_sym)

      selected = if requested
        configs.slice(*requested)
      else
        configs
      end

      selected.each_with_object({}) do |(key, config), hash|
        runner = QueryRunner.new(key, config, period: period_param, latest_override: latest_override)
        hash[key] = runner.call
      end
    end

    def build_period_info
      days = resolve_display_period
      if days
        { from: days.days.ago.to_date.iso8601, to: Date.current.iso8601, days: days }
      else
        { from: nil, to: Date.current.iso8601, days: "all" }
      end
    end

    def resolve_display_period
      period_key = period_param || AgentGateway.configuration.default_period
      QueryRunner::PERIODS.fetch(period_key) { QueryRunner::PERIODS.fetch(AgentGateway.configuration.default_period, 7) }
    end

    def period_param
      params[:period].presence
    end

    def latest_override
      params[:latest]&.to_i&.then { |n| n > 0 ? n : nil }
    end
  end
end
