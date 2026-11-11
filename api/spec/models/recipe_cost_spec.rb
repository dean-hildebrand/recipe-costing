require "rails_helper"

# Reference check from spec.md, built from the same numbers as db/seeds.rb.
# Fixture rows persist in the test DB, so reuse the fixture ingredients that
# match the seeds and create only the three the fixtures don't have.
RSpec.describe "Recipe costing", type: :model do
  fixtures :ingredients
  def ingredient(name, qty, unit, price_cents, yield_percent)
    Ingredient.create!(
      name: name,
      purchase_quantity: qty,
      purchase_unit: unit,
      purchase_price_cents: price_cents,
      yield_percent: yield_percent
    )
  end

  let(:rice)     { ingredients(:arborio_rice) }  # 1 kg, 390¢, 100%
  let(:stock)    { ingredients(:chicken_stock) } # 5 l, 950¢, 100%
  let(:butter)   { ingredients(:butter) }        # 1 kg, 950¢, 100%
  let(:parmesan) { ingredients(:parmesan) }      # 1 kg, 2400¢, 95%
  let(:salt)     { ingredients(:sea_salt) }      # 1 kg, 120¢, 100%
  let(:wine)     { ingredient("Dry white wine",         "750", "ml", 550,  100) }
  let(:onion)    { ingredient("Yellow onion",           "5",   "kg", 475,  90) }
  let(:oil)      { ingredient("Extra virgin olive oil", "5",   "l",  4200, 100) }

  let(:risotto) do
    Recipe.create!(name: "Reference Risotto", servings: 4, menu_price_cents: 1850).tap do |r|
      [
        [ rice,     "320", "g" ],
        [ stock,    "1.2", "l" ],
        [ wine,     "150", "ml" ],
        [ onion,    "120", "g" ],
        [ butter,   "60",  "g" ],
        [ parmesan, "80",  "g" ],
        [ oil,      "30",  "ml" ],
        [ salt,     "8",   "g" ]
      ].each do |ing, qty, unit|
        r.recipe_ingredients.create!(ingredient: ing, quantity: qty, unit: unit)
      end
    end
  end

  describe Ingredient do
    it "returns cost per base unit as a BigDecimal" do
      expect(rice.cost_per_base_unit).to be_a(BigDecimal)
      expect(rice.cost_per_base_unit).to eq(BigDecimal("0.39")) # 390¢ / 1000 g
    end

    it "applies yield: 90% usable onion costs more per gram" do
      # 475¢ / (5000 g × 0.9) = 0.10555…¢/g, not 0.095
      expect(onion.cost_per_base_unit).to be_within(BigDecimal("0.000001")).of(BigDecimal("475") / 4500)
    end
  end

  describe RecipeIngredient do
    def line_for(ing)
      risotto.recipe_ingredients.find_by!(ingredient: ing)
    end

    it "returns an unrounded BigDecimal line cost" do
      cost = line_for(rice).cost
      expect(cost).to be_a(BigDecimal)
      expect(cost).to eq(BigDecimal("124.8")) # would be 125 if rounded per line
    end

    it "converts the line unit to the base unit (1.2 l of stock)" do
      expect(line_for(stock).cost).to eq(BigDecimal("228")) # 0.19¢/ml × 1200 ml
    end

    it "includes yield in the line cost (parmesan at 95%)" do
      # 2400 / 950 × 80 = 202.105…, not 192
      expect(line_for(parmesan).cost).to be_within(BigDecimal("0.001")).of(BigDecimal("202.105"))
    end
  end

  describe Recipe do
    it "sums unrounded line costs to about 760.73¢" do
      exact = risotto.recipe_ingredients.sum(&:cost)
      expect(exact).to be_a(BigDecimal)
      expect(exact).to be_within(BigDecimal("0.01")).of(BigDecimal("760.73"))
    end

    it "rounds batch cost once, to whole cents" do
      expect(risotto.batch_cost_cents).to eq(761)
    end

    it "has a plate cost of 190¢" do
      expect(risotto.plate_cost_cents).to eq(190)
    end

    it "has a food cost of 10.3%" do
      expect(risotto.food_cost_percent).to eq(BigDecimal("10.3"))
    end

    it "has a margin of 1660¢" do
      expect(risotto.margin_cents).to eq(1660)
    end

    it "returns integer cents" do
      expect(risotto.plate_cost_cents).to be_an(Integer)
      expect(risotto.margin_cents).to be_an(Integer)
    end

    context "without a menu price" do
      before { risotto.update!(menu_price_cents: nil) }

      it "has no food cost % or margin" do
        expect(risotto.food_cost_percent).to be_nil
        expect(risotto.margin_cents).to be_nil
      end

      it "still has a plate cost" do
        expect(risotto.plate_cost_cents).to eq(190)
      end
    end

    it "computes costs for unsaved lines (what the preview endpoint will do)" do
      recipe = Recipe.new(name: "Preview", servings: 2, menu_price_cents: 1000)
      recipe.recipe_ingredients.build(ingredient: rice, quantity: "500", unit: "g")
      expect(recipe.plate_cost_cents).to eq(98) # 195¢ / 2 = 97.5 → 98
    end
  end
end
