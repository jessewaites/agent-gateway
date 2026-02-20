module AgentGateway
  class QueryRunner
    PERIODS = {
      "1d"  => 1,
      "7d"  => 7,
      "30d" => 30,
      "90d" => 90,
      "1y"  => 365,
      "all" => nil
    }.freeze

    def initialize(resource_key, config, period: nil, latest_override: nil)
      @resource_key = resource_key
      @config = config
      @period = period
      @latest_override = latest_override
    end

    def call
      model = @config.model_name.constantize
      relation = base_relation(model)

      result = {}
      result[:count] = relation.count if @config.count_enabled?
      result[:sum] = compute_sums(relation) unless @config.sum_columns.empty?
      result[:avg] = compute_avgs(relation) unless @config.avg_columns.empty?
      result[:latest] = fetch_latest(relation) if latest_count

      result
    rescue NameError
      { error: "Model not found: #{@config.model_name}" }
    end

    private

    def base_relation(model)
      relation = @config.scope_name ? model.public_send(@config.scope_name) : model.all
      apply_period_filter(relation)
    end

    def apply_period_filter(relation)
      days = resolve_period
      return relation unless days

      date_col = @config.date_column_name
      relation.where(date_col => days.days.ago..)
    end

    def resolve_period
      period_key = @period || AgentGateway.configuration.default_period
      return nil if period_key == "all"

      PERIODS.fetch(period_key) { PERIODS.fetch(AgentGateway.configuration.default_period, 7) }
    end

    def compute_sums(relation)
      @config.sum_columns.each_with_object({}) do |col, hash|
        hash[col] = (relation.sum(col.to_sym) || 0).round(2)
      end
    end

    def compute_avgs(relation)
      @config.avg_columns.each_with_object({}) do |col, hash|
        hash[col] = (relation.average(col.to_sym) || 0).to_f.round(2)
      end
    end

    def latest_count
      @latest_override || @config.latest_count
    end

    def fetch_latest(relation)
      records = relation.order(created_at: :desc).limit(latest_count)
      if @config.attributes_list.any?
        records.map { |r| @config.attributes_list.each_with_object({}) { |a, h| h[a] = r.public_send(a) } }
      else
        records.map { |r| { "id" => r.id } }
      end
    end
  end
end
