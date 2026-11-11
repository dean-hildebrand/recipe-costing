require "rails_helper"

RSpec.describe "Api::V1::Ingredients", type: :request do
  fixtures :ingredients, :recipes, :recipe_ingredients

  let(:json) { JSON.parse(response.body) }
  let(:rice) { ingredients(:arborio_rice) } # used by the risotto fixture
  let(:salt) { ingredients(:sea_salt) }     # not used by any recipe

  let(:valid_attributes) do
    {
      name: "Shallots",
      purchase_quantity: "2.5",
      purchase_unit: "kg",
      purchase_price_cents: 625,
      yield_percent: "88"
    }
  end

  describe "GET /api/v1/ingredients" do
    it "returns every ingredient, ordered by name" do
      get api_v1_ingredients_path

      expect(response).to have_http_status(:ok)
      expect(json.map { _1["name"] }).to eq(Ingredient.order(:name).pluck(:name))
    end

    it "serialises only the public fields, with decimals as strings" do
      get api_v1_ingredients_path

      parmesan = json.find { _1["name"] == "Parmigiano Reggiano" }
      expect(parmesan.keys).to match_array(%w[id name purchase_quantity purchase_unit purchase_price_cents yield_percent])
      expect(parmesan).to include(
        "purchase_quantity" => "1.0",
        "purchase_unit" => "kg",
        "purchase_price_cents" => 2400,
        "yield_percent" => "95.0"
      )
    end

    it "returns an empty array, not 204, when there are no ingredients" do
      RecipeIngredient.delete_all
      Ingredient.delete_all

      get api_v1_ingredients_path

      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
    end
  end

  describe "GET /api/v1/ingredients/:id" do
    it "returns the ingredient" do
      get api_v1_ingredient_path(rice)

      expect(response).to have_http_status(:ok)
      expect(json).to include("id" => rice.id, "name" => "Arborio rice")
    end

    it "returns 404 in the error format for an unknown id" do
      get api_v1_ingredient_path(id: 0)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("errors" => { "base" => [ "Ingredient not found" ] })
    end
  end

  describe "POST /api/v1/ingredients" do
    it "creates the ingredient and returns 201" do
      expect {
        post api_v1_ingredients_path, params: { ingredient: valid_attributes }, as: :json
      }.to change(Ingredient, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include(
        "name" => "Shallots",
        "purchase_quantity" => "2.5",
        "purchase_price_cents" => 625,
        "yield_percent" => "88.0"
      )
    end

    it "returns 422 with errors keyed by field" do
      post api_v1_ingredients_path,
           params: { ingredient: valid_attributes.merge(purchase_price_cents: -1, purchase_unit: "cup") },
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to match_array(%w[purchase_price_cents purchase_unit])
      expect(json["errors"]["purchase_price_cents"]).to include("must be greater than or equal to 0")
    end

    it "returns 422 for a duplicate name, ignoring case" do
      post api_v1_ingredients_path, params: { ingredient: valid_attributes.merge(name: "arborio RICE") }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["name"]).to include("has already been taken")
    end

    it "returns 400 when the ingredient root key is missing" do
      post api_v1_ingredients_path, params: { something_else: {} }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(json["errors"]["base"]).to be_present
    end

    it "ignores attributes that aren't permitted" do
      post api_v1_ingredients_path, params: { ingredient: valid_attributes.merge(id: 999_999) }, as: :json

      expect(response).to have_http_status(:created)
      expect(json["id"]).not_to eq(999_999)
    end
  end

  describe "PATCH /api/v1/ingredients/:id" do
    it "updates the ingredient" do
      patch api_v1_ingredient_path(rice), params: { ingredient: { purchase_price_cents: 420 } }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["purchase_price_cents"]).to eq(420)
      expect(rice.reload.purchase_price_cents).to eq(420)
    end

    it "returns 422 and leaves the record unchanged when invalid" do
      patch api_v1_ingredient_path(rice), params: { ingredient: { yield_percent: "0" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("yield_percent")
      expect(rice.reload.yield_percent).to eq(100)
    end

    it "returns 404 for an unknown id" do
      patch api_v1_ingredient_path(id: 0), params: { ingredient: { purchase_price_cents: 1 } }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/ingredients/:id" do
    it "deletes an unused ingredient and returns 204" do
      expect { delete api_v1_ingredient_path(salt) }.to change(Ingredient, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 422 when a recipe uses the ingredient" do
      expect { delete api_v1_ingredient_path(rice) }.not_to change(Ingredient, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["base"]).to include("Cannot delete record because dependent recipe ingredients exist")
    end

    it "returns 404 for an unknown id" do
      delete api_v1_ingredient_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end
end
