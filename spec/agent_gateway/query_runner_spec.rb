require "spec_helper"

RSpec.describe AgentGateway::QueryRunner do
  def build_config(model_name, &block)
    config = AgentGateway::ResourceConfig.new(model_name)
    config.instance_eval(&block) if block
    config
  end

  describe "#call" do
    describe "count" do
      it "returns count of records" do
        User.create!(name: "Alice", email: "a@example.com")
        User.create!(name: "Bob", email: "b@example.com")
        User.create!(name: "Carol", email: "c@example.com")

        config = build_config("User") { count }
        result = described_class.new(:users, config, period: "all").call

        expect(result).to eq(count: 3)
      end
    end

    describe "sum" do
      it "returns sum of column rounded to 2 decimals" do
        user = User.create!(name: "Alice", email: "a@example.com")
        Order.create!(total: 10.556, user: user)
        Order.create!(total: 20.333, user: user)
        Order.create!(total: 30.111, user: user)

        config = build_config("Order") { sum "total" }
        result = described_class.new(:orders, config, period: "all").call

        expect(result).to eq(sum: { "total" => 61.0 })
      end
    end

    describe "avg" do
      it "returns average of column rounded to 2 decimals" do
        user = User.create!(name: "Alice", email: "a@example.com")
        Order.create!(total: 10.00, user: user)
        Order.create!(total: 20.00, user: user)
        Order.create!(total: 30.00, user: user)

        config = build_config("Order") { avg "total" }
        result = described_class.new(:orders, config, period: "all").call

        expect(result).to eq(avg: { "total" => 20.0 })
      end
    end

    describe "latest" do
      it "returns array of hashes with only specified attributes" do
        User.create!(name: "Alice", email: "a@example.com")
        User.create!(name: "Bob", email: "b@example.com")
        User.create!(name: "Carol", email: "c@example.com")

        config = build_config("User") do
          latest 2
          attributes :email, :name
        end
        result = described_class.new(:users, config, period: "all").call

        expect(result[:latest].length).to eq(2)
        result[:latest].each do |record|
          expect(record.keys).to match_array(%w[email name])
        end
        expect(result[:latest].first["name"]).to eq("Carol")
        expect(result[:latest].last["name"]).to eq("Bob")
      end
    end

    describe "period filtering" do
      it "only includes records within the period" do
        User.create!(name: "Recent", email: "r@example.com", created_at: 1.day.ago)
        User.create!(name: "Old", email: "o@example.com", created_at: 30.days.ago)

        config = build_config("User") { count }
        result = described_class.new(:users, config, period: "7d").call

        expect(result).to eq(count: 1)
      end
    end

    describe "scope" do
      it "applies named scope to query" do
        User.create!(name: "Recent", email: "r@example.com", created_at: 1.day.ago)
        User.create!(name: "Old", email: "o@example.com", created_at: 30.days.ago)

        config = build_config("User") do
          scope :recent
          count
        end
        result = described_class.new(:users, config, period: "all").call

        expect(result).to eq(count: 1)
      end
    end

    describe "attribute allowlist" do
      it "only includes specified attributes in latest records" do
        User.create!(name: "Alice", email: "a@example.com")

        config = build_config("User") do
          latest 1
          attributes :email
        end
        result = described_class.new(:users, config, period: "all").call

        expect(result[:latest].first.keys).to eq(%w[email])
        expect(result[:latest].first).not_to have_key("name")
        expect(result[:latest].first).not_to have_key("id")
      end
    end

    describe "model not found" do
      it "returns error hash for nonexistent model" do
        config = build_config("NonexistentModel")
        result = described_class.new(:nonexistent, config, period: "all").call

        expect(result).to eq(error: "Model not found: NonexistentModel")
      end
    end

    describe "empty results" do
      it "returns 0 for count" do
        config = build_config("User") { count }
        result = described_class.new(:users, config, period: "all").call

        expect(result).to eq(count: 0)
      end

      it "returns empty array for latest" do
        config = build_config("User") do
          latest 5
          attributes :name
        end
        result = described_class.new(:users, config, period: "all").call

        expect(result).to eq(latest: [])
      end

      it "returns 0 for sum" do
        config = build_config("Order") { sum "total" }
        result = described_class.new(:orders, config, period: "all").call

        expect(result).to eq(sum: { "total" => 0 })
      end
    end

    describe "multiple sum/avg columns" do
      it "returns hash with multiple keys for sum" do
        user = User.create!(name: "Alice", email: "a@example.com")
        Order.create!(total: 10.00, user: user, status: "complete")
        Order.create!(total: 20.00, user: user, status: "pending")

        config = build_config("Order") do
          sum "total"
          sum "user_id"
        end
        result = described_class.new(:orders, config, period: "all").call

        expect(result[:sum].keys).to match_array(%w[total user_id])
        expect(result[:sum]["total"]).to eq(30.0)
      end

      it "returns hash with multiple keys for avg" do
        user = User.create!(name: "Alice", email: "a@example.com")
        Order.create!(total: 10.00, user: user)
        Order.create!(total: 30.00, user: user)

        config = build_config("Order") do
          avg "total"
          avg "user_id"
        end
        result = described_class.new(:orders, config, period: "all").call

        expect(result[:avg].keys).to match_array(%w[total user_id])
        expect(result[:avg]["total"]).to eq(20.0)
      end
    end
  end
end
