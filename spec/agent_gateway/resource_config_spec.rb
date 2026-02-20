require "spec_helper"

RSpec.describe AgentGateway::ResourceConfig do
  subject(:config) { described_class.new("Order") }

  describe "#model_name" do
    it "stores model_name from constructor" do
      expect(config.model_name).to eq("Order")
    end
  end

  describe "#attributes" do
    it "sets and returns attributes_list as strings" do
      config.attributes(:name, :email, :age)

      expect(config.attributes_list).to eq(%w[name email age])
    end
  end

  describe "#count" do
    it "enables counting" do
      config.count

      expect(config.count_enabled?).to be true
    end

    it "reflects disabled counting via count_enabled?" do
      expect(config.count_enabled?).to be false

      config.count(true)
      expect(config.count_enabled?).to be true

      config.count(false)
      expect(config.count_enabled?).to be false
    end
  end

  describe "#latest" do
    it "sets latest_count" do
      config.latest(10)

      expect(config.latest_count).to eq(10)
    end
  end

  describe "#sum" do
    it "appends to sum_columns on multiple calls" do
      config.sum(:total)
      config.sum(:tax)
      config.sum(:shipping)

      expect(config.sum_columns).to eq(%w[total tax shipping])
    end
  end

  describe "#avg" do
    it "appends to avg_columns on multiple calls" do
      config.avg(:price)
      config.avg(:rating)
      config.avg(:weight)

      expect(config.avg_columns).to eq(%w[price rating weight])
    end
  end

  describe "#scope" do
    it "sets scope_name" do
      config.scope(:active)

      expect(config.scope_name).to eq(:active)
    end
  end

  describe "#date_column" do
    it "sets date_column_name as symbol" do
      config.date_column("ordered_at")

      expect(config.date_column_name).to eq(:ordered_at)
    end
  end

  describe "defaults" do
    it "has empty attributes_list" do
      expect(config.attributes_list).to eq([])
    end

    it "has count_enabled? as false" do
      expect(config.count_enabled?).to be false
    end

    it "has latest_count as nil" do
      expect(config.latest_count).to be_nil
    end

    it "has empty sum_columns" do
      expect(config.sum_columns).to eq([])
    end

    it "has empty avg_columns" do
      expect(config.avg_columns).to eq([])
    end

    it "has scope_name as nil" do
      expect(config.scope_name).to be_nil
    end

    it "has date_column_name defaulting to :created_at" do
      expect(config.date_column_name).to eq(:created_at)
    end
  end
end
