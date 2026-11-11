require "rails_helper"

RSpec.describe RecipeIngredient, type: :model do
  fixtures :recipes, :ingredients, :recipe_ingredients

  # staff_meal has no lines yet, so adding butter to it isn't a duplicate.
  def build_line(**overrides)
    RecipeIngredient.new(
      recipe: recipes(:staff_meal),
      ingredient: ingredients(:butter),
      quantity: 1,
      unit: "kg",
      **overrides
    )
  end

  it "is valid with valid attributes" do
    expect(build_line).to be_valid
  end

  describe "recipe" do
    it "is invalid without a recipe" do
      line = build_line(recipe: nil)
      expect(line).not_to be_valid
      expect(line.errors[:recipe]).to include("must exist")
    end
  end

  describe "ingredient" do
    it "is invalid without an ingredient" do
      line = build_line(ingredient: nil)
      expect(line).not_to be_valid
      expect(line.errors[:ingredient]).to include("must exist")
    end

    it "is valid when the ingredient is already used by a different recipe" do
      # butter is already in risotto; staff_meal is a different recipe
      expect(build_line).to be_valid
    end

    it "is invalid when the ingredient is already in this recipe" do
      line = build_line(recipe: recipes(:risotto))
      expect(line).not_to be_valid
      expect(line.errors[:ingredient_id]).to include("is already in this recipe")
    end
  end

  describe "quantity" do
    it "is valid when greater than 0" do
      expect(build_line(quantity: "0.001")).to be_valid
    end

    it "is invalid without a quantity" do
      line = build_line(quantity: nil)
      expect(line).not_to be_valid
      expect(line.errors[:quantity]).to be_present
    end

    it "is invalid when 0" do
      line = build_line(quantity: 0)
      expect(line).not_to be_valid
      expect(line.errors[:quantity]).to be_present
    end
  end

  describe "unit" do
    it "is invalid without a unit" do
      line = build_line(unit: nil)
      expect(line).not_to be_valid
      expect(line.errors[:unit]).to be_present
    end

    it "is invalid for an unknown unit" do
      line = build_line(unit: "cup")
      expect(line).not_to be_valid
      expect(line.errors[:unit]).to be_present
    end

    it "is valid when a different unit of the same dimension as the purchase unit" do
      # butter is bought in kg; g is also mass
      expect(build_line(unit: "g")).to be_valid
    end

    it "is invalid when the dimension doesn't match the ingredient's purchase unit, and names the ingredient" do
      line = build_line(ingredient: ingredients(:arborio_rice), quantity: 200, unit: "ml")

      expect(line).not_to be_valid
      expect(line.errors[:unit]).to include("ml can't be used for Arborio rice, which is bought in kg")
    end
  end
end
