require "rails_helper"

# Fixture risotto: rice 320 g (124.8¢), stock 1.2 l (228¢), butter 60 g (57¢),
# parmesan 80 g at 95% yield (202.105…¢) → batch 611.905¢, 4 servings, menu 1850¢.
RSpec.describe "Api::V1::Recipes", type: :request do
  fixtures :ingredients, :recipes, :recipe_ingredients

  let(:json) { JSON.parse(response.body) }
  let(:risotto) { recipes(:risotto) }
  let(:rice) { ingredients(:arborio_rice) }
  let(:stock) { ingredients(:chicken_stock) }
  let(:salt) { ingredients(:sea_salt) }
  let(:lemons) { ingredients(:lemons) }

  def count_queries(&block)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  describe "GET /api/v1/recipes" do
    it "lists recipes by name with their costs" do
      get api_v1_recipes_path

      expect(response).to have_http_status(:ok)
      expect(json.map { _1["name"] }).to eq(Recipe.order(:name).pluck(:name))

      row = json.find { _1["name"] == "Parmesan Risotto" }
      expect(row).to eq(
        "id" => risotto.id,
        "name" => "Parmesan Risotto",
        "servings" => 4,
        "menu_price_cents" => 1850,
        "batch_cost_cents" => 612,
        "plate_cost_cents" => 153,
        "food_cost_percent" => "8.3",
        "margin_cents" => 1697
      )
    end

    it "returns null food cost and margin for a recipe without a menu price" do
      get api_v1_recipes_path

      row = json.find { _1["name"] == "Staff Meal" }
      expect(row).to include("plate_cost_cents" => 0, "food_cost_percent" => nil, "margin_cents" => nil)
    end

    it "runs a fixed number of queries however many recipes there are (no N+1)" do
      baseline = count_queries { get api_v1_recipes_path }

      extra = Recipe.create!(name: "Extra", servings: 1)
      extra.recipe_ingredients.create!(ingredient: salt, quantity: "5", unit: "g")
      extra.recipe_ingredients.create!(ingredient: lemons, quantity: "2", unit: "each")

      expect(count_queries { get api_v1_recipes_path }).to eq(baseline)
    end
  end

  describe "GET /api/v1/recipes/:id" do
    it "returns the recipe with its lines and line costs" do
      get api_v1_recipe_path(risotto)

      expect(response).to have_http_status(:ok)
      expect(json).to include(
        "id" => risotto.id,
        "notes" => risotto.notes,
        "batch_cost_cents" => 612,
        "plate_cost_cents" => 153,
        "food_cost_percent" => "8.3",
        "margin_cents" => 1697
      )

      rice_line = json["recipe_ingredients"].find { _1["ingredient_id"] == rice.id }
      expect(rice_line).to eq(
        "id" => recipe_ingredients(:risotto_rice).id,
        "ingredient_id" => rice.id,
        "ingredient" => { "id" => rice.id, "name" => "Arborio rice", "purchase_unit" => "kg" },
        "quantity" => "320.0",
        "unit" => "g",
        "cost_cents" => 125
      )
      expect(json["recipe_ingredients"].size).to eq(4)
    end

    it "returns 404 in the error format for an unknown id" do
      get api_v1_recipe_path(id: 0)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("errors" => { "base" => [ "Recipe not found" ] })
    end
  end

  describe "POST /api/v1/recipes" do
    let(:params) do
      {
        recipe: {
          name: "Rice and Stock",
          servings: 2,
          menu_price_cents: 900,
          recipe_ingredients_attributes: [
            { ingredient_id: rice.id, quantity: "200", unit: "g" },  # 78¢
            { ingredient_id: stock.id, quantity: "500", unit: "ml" } # 95¢
          ]
        }
      }
    end

    it "creates the recipe and its lines in one request" do
      expect {
        post api_v1_recipes_path, params: params, as: :json
      }.to change(Recipe, :count).by(1).and change(RecipeIngredient, :count).by(2)

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Rice and Stock", "batch_cost_cents" => 173, "plate_cost_cents" => 87)
      expect(json["recipe_ingredients"].map { _1["cost_cents"] }).to eq([ 78, 95 ])
    end

    it "returns 422 for invalid recipe fields" do
      params[:recipe].merge!(name: "", servings: 0)

      expect { post api_v1_recipes_path, params: params, as: :json }.not_to change(Recipe, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to match_array(%w[name servings])
    end

    it "keys a bad line's error by its position and saves nothing" do
      params[:recipe][:recipe_ingredients_attributes][1][:unit] = "g" # stock is bought in l

      expect {
        post api_v1_recipes_path, params: params, as: :json
      }.not_to change(RecipeIngredient, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["recipe_ingredients[1].unit"])
        .to eq([ "g can't be used for Chicken stock, which is bought in l" ])
    end

    it "returns 422, not a 500, when the same ingredient is added twice" do
      params[:recipe][:recipe_ingredients_attributes] << { ingredient_id: rice.id, quantity: "10", unit: "g" }

      post api_v1_recipes_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["recipe_ingredients"]).to include("can't include the same ingredient twice")
    end

    it "returns 422 for an ingredient that doesn't exist" do
      params[:recipe][:recipe_ingredients_attributes][0][:ingredient_id] = 0

      post api_v1_recipes_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["recipe_ingredients[0].ingredient"]).to include("must exist")
    end
  end

  describe "PATCH /api/v1/recipes/:id" do
    it "updates, removes and adds lines in one request" do
      patch api_v1_recipe_path(risotto), as: :json, params: {
        recipe: {
          servings: 2,
          recipe_ingredients_attributes: [
            { id: recipe_ingredients(:risotto_rice).id, quantity: "400" },
            { id: recipe_ingredients(:risotto_butter).id, _destroy: true },
            { ingredient_id: salt.id, quantity: "8", unit: "g" }
          ]
        }
      }

      expect(response).to have_http_status(:ok)

      lines = risotto.reload.recipe_ingredients
      expect(lines.map { _1.ingredient.name }).to contain_exactly(
        "Arborio rice", "Chicken stock", "Parmigiano Reggiano", "Sea salt"
      )
      expect(lines.find { _1.ingredient == rice }.quantity).to eq(400)

      # 156 rice + 228 stock + 202.105 parmesan + 0.96 salt = 587.065 → /2 = 293.53
      expect(json["recipe_ingredients"].size).to eq(4)
      expect(json).to include("servings" => 2, "batch_cost_cents" => 587, "plate_cost_cents" => 294)
    end

    it "returns 422 and changes nothing when one line is invalid" do
      patch api_v1_recipe_path(risotto), as: :json, params: {
        recipe: {
          servings: 2,
          recipe_ingredients_attributes: [
            { id: recipe_ingredients(:risotto_butter).id, _destroy: true },
            { id: recipe_ingredients(:risotto_rice).id, unit: "ml" }
          ]
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("recipe_ingredients[1].unit")

      risotto.reload
      expect(risotto.servings).to eq(4)
      expect(risotto.recipe_ingredients.size).to eq(4)
    end

    it "returns 404 for an unknown id" do
      patch api_v1_recipe_path(id: 0), params: { recipe: { servings: 2 } }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/recipes/:id" do
    it "deletes the recipe and its lines" do
      expect {
        delete api_v1_recipe_path(risotto)
      }.to change(Recipe, :count).by(-1).and change(RecipeIngredient, :count).by(-4)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for an unknown id" do
      delete api_v1_recipe_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/recipes/preview" do
    let(:params) do
      {
        recipe: {
          name: "Parmesan Risotto", # an existing name is fine: preview skips uniqueness
          servings: 4,
          menu_price_cents: 1850,
          recipe_ingredients_attributes: [
            { ingredient_id: rice.id, quantity: "320", unit: "g" },
            { ingredient_id: stock.id, quantity: "1.2", unit: "l" }
          ]
        }
      }
    end

    it "returns computed costs without saving anything" do
      expect {
        post preview_api_v1_recipes_path, params: params, as: :json
      }.not_to change { [ Recipe.count, RecipeIngredient.count ] }

      expect(response).to have_http_status(:ok)
      # 124.8 + 228 = 352.8 → /4 = 88.2
      expect(json).to include(
        "id" => nil,
        "batch_cost_cents" => 353,
        "plate_cost_cents" => 88,
        "food_cost_percent" => "4.8",
        "margin_cents" => 1762
      )
      expect(json["recipe_ingredients"].map { _1["cost_cents"] }).to eq([ 125, 228 ])
      expect(json["recipe_ingredients"].map { _1["id"] }).to eq([ nil, nil ])
    end

    it "returns 422 when servings is 0 (plate cost can't be computed)" do
      params[:recipe][:servings] = 0

      post preview_api_v1_recipes_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to eq([ "servings" ])
    end

    it "returns 422 for an incompatible unit on a line" do
      params[:recipe][:recipe_ingredients_attributes][0][:unit] = "ml"

      post preview_api_v1_recipes_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("recipe_ingredients[0].unit")
    end
  end
end
