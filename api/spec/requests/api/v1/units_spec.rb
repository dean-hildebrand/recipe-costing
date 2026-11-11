require 'rails_helper'

RSpec.describe "Api::V1::Units", type: :request do
  describe "GET array of units available" do
    it "returns a list of units" do
      get api_v1_units_path
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to eq(
        "g" => "mass", "kg" => "mass", "ml" => "volume", "l" => "volume", "each" => "count"
      )
    end
  end
end
