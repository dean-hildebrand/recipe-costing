require "rails_helper"

RSpec.describe Recipe, type: :model do
  fixtures :recipes, :ingredients, :recipe_ingredients

  let(:recipe) { recipes(:risotto) }

  it "is valid with the fixture's attributes" do
    expect(recipe).to be_valid
  end

  describe "name" do
    it "is valid when present" do
      recipe.name = "Mushroom Risotto"
      expect(recipe).to be_valid
    end

    it "is invalid when blank" do
      recipe.name = ""
      expect(recipe).not_to be_valid
      expect(recipe.errors[:name]).to include("can't be blank")
    end

    it "is valid when no other recipe has the name" do
      expect(Recipe.new(name: "Mushroom Risotto", servings: 2)).to be_valid
    end

    it "is invalid when another recipe has the same name, ignoring case" do
      duplicate = Recipe.new(name: "parmesan risotto", servings: 2)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "servings" do
    it "is valid when a positive whole number" do
      recipe.servings = 1
      expect(recipe).to be_valid
    end

    it "is invalid when 0" do
      recipe.servings = 0
      expect(recipe).not_to be_valid
      expect(recipe.errors[:servings]).to be_present
    end

    it "is invalid when not a whole number" do
      recipe.servings = "2.5"
      expect(recipe).not_to be_valid
      expect(recipe.errors[:servings]).to be_present
    end
  end

  describe "menu_price_cents" do
    it "is valid when nil" do
      expect(recipes(:staff_meal)).to be_valid
    end

    it "is valid when 0" do
      recipe.menu_price_cents = 0
      expect(recipe).to be_valid
    end

    it "is invalid when negative" do
      recipe.menu_price_cents = -1
      expect(recipe).not_to be_valid
      expect(recipe.errors[:menu_price_cents]).to be_present
    end

    it "is invalid when not a whole number of cents" do
      recipe.menu_price_cents = "18.5"
      expect(recipe).not_to be_valid
      expect(recipe.errors[:menu_price_cents]).to be_present
    end
  end

  describe "destroying" do
    it "removes the recipe's lines (ON DELETE CASCADE)" do
      line_ids = recipe.recipe_ingredients.ids
      expect(line_ids).not_to be_empty

      expect { recipe.destroy }.to change(RecipeIngredient, :count).by(-line_ids.size)
      expect(RecipeIngredient.where(id: line_ids)).to be_empty
    end

    it "leaves the ingredients in place" do
      expect { recipe.destroy }.not_to change(Ingredient, :count)
    end
  end
end
