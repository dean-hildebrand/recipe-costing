require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "returns 200 from /up" do
    get rails_health_check_path

    expect(response).to have_http_status(:ok)
  end

  it "can reach the database" do
    expect(ActiveRecord::Base.connection.select_value("SELECT 1")).to eq(1)
  end
end
