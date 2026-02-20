require "spec_helper"

RSpec.describe "Briefings endpoint", type: :request do
  let(:base_url) { "/agent-gateway/test-secret/briefing" }
  let(:auth_headers) { { "Authorization" => "Bearer test-token" } }

  def setup_resources
    AgentGateway.configure do |c|
      c.expose(:users, model: "User") { count; latest 2; attributes :email, :name }
      c.expose(:orders, model: "Order") { count; sum "total"; avg "total" }
    end
  end

  def json
    JSON.parse(response.body)
  end

  describe "authentication and authorization" do
    it "returns 404 for wrong path_secret" do
      get "/agent-gateway/wrong-secret/briefing", headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 when Authorization header is missing" do
      get base_url
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 for wrong bearer token" do
      get base_url, headers: { "Authorization" => "Bearer bad-token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "successful briefing" do
    before do
      setup_resources
      @alice = User.create!(email: "alice@example.com", name: "Alice")
      @bob   = User.create!(email: "bob@example.com",   name: "Bob")
      @carol = User.create!(email: "carol@example.com",  name: "Carol")
      Order.create!(total: 10.0, status: "paid",    user: @alice)
      Order.create!(total: 20.0, status: "pending", user: @bob)
      Order.create!(total: 30.0, status: "paid",    user: @carol)
    end

    it "returns 200 with correct JSON structure" do
      get base_url, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["app_name"]).to eq("TestApp")
      expect(json["generated_at"]).to be_present
      expect(json["period"]).to include("from", "to", "days")
      expect(json["period"]["days"]).to eq(7)

      users_data = json["data"]["users"]
      expect(users_data["count"]).to eq(3)
      expect(users_data["latest"].length).to eq(2)

      orders_data = json["data"]["orders"]
      expect(orders_data["count"]).to eq(3)
      expect(orders_data["sum"]["total"].to_f).to eq(60.0)
      expect(orders_data["avg"]["total"].to_f).to eq(20.0)
    end
  end

  describe "resource filtering" do
    before do
      setup_resources
      User.create!(email: "a@example.com", name: "A")
      Order.create!(total: 5.0, status: "paid", user: User.first)
    end

    it "returns only requested resources with ?resources=users" do
      get "#{base_url}?resources=users", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to have_key("users")
      expect(json["data"]).not_to have_key("orders")
    end

    it "returns empty data hash for ?resources=nonexistent" do
      get "#{base_url}?resources=nonexistent", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]).to eq({})
    end
  end

  describe "period override" do
    before { setup_resources }

    it "respects ?period=30d" do
      get "#{base_url}?period=30d", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["period"]["days"]).to eq(30)
    end
  end

  describe "latest override" do
    before do
      setup_resources
      User.create!(email: "a@example.com", name: "A")
      User.create!(email: "b@example.com", name: "B")
      User.create!(email: "c@example.com", name: "C")
    end

    it "respects ?latest=1 override" do
      get "#{base_url}?latest=1", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]["users"]["latest"].length).to eq(1)
    end
  end

  describe "attribute allowlisting" do
    before do
      setup_resources
      User.create!(email: "a@example.com", name: "A")
    end

    it "only includes allowed attributes in latest records" do
      get base_url, headers: auth_headers

      record = json["data"]["users"]["latest"].first
      expect(record.keys).to match_array(%w[email name])
    end
  end

  describe "empty database" do
    before { setup_resources }

    it "returns 0 counts and empty latest arrays" do
      get base_url, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json["data"]["users"]["count"]).to eq(0)
      expect(json["data"]["users"]["latest"]).to eq([])
      expect(json["data"]["orders"]["count"]).to eq(0)
    end
  end
end
