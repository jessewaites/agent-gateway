module AgentGateway
  class ResourceConfig
    attr_reader :model_name

    def initialize(model_name)
      @model_name = model_name
      @attributes_list = []
      @count_enabled = false
      @latest_count = nil
      @sum_columns = []
      @avg_columns = []
      @scope_name = nil
      @date_column_name = :created_at
    end

    def attributes(*attrs)
      @attributes_list = attrs.map(&:to_s)
    end

    def attributes_list
      @attributes_list
    end

    def count(enabled = true)
      @count_enabled = enabled
    end

    def count_enabled?
      @count_enabled
    end

    def latest(n)
      @latest_count = n
    end

    def latest_count
      @latest_count
    end

    def sum(column)
      @sum_columns << column.to_s
    end

    def sum_columns
      @sum_columns
    end

    def avg(column)
      @avg_columns << column.to_s
    end

    def avg_columns
      @avg_columns
    end

    def scope(name)
      @scope_name = name
    end

    def scope_name
      @scope_name
    end

    def date_column(name)
      @date_column_name = name.to_sym
    end

    def date_column_name
      @date_column_name
    end
  end
end
