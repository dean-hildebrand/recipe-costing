require "rails_helper"

RSpec.describe Ingredient, type: :model do
  fixtures :recipes, :ingredients, :recipe_ingredients

  let(:ingredient) { ingredients(:arborio_rice) }

  it "is valid with the fixture's attributes" do
    expect(ingredient).to be_valid
  end

  describe "name" do
    it "is valid when present" do
      ingredient.name = "Carnaroli rice"
      expect(ingredient).to be_valid
    end

    it "is invalid when blank" do
      ingredient.name = ""
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:name]).to include("can't be blank")
    end

    it "is valid when no other ingredient has the name" do
      expect(Ingredient.new(ingredient.attributes.except("id").merge("name" => "Carnaroli rice"))).to be_valid
    end

    it "is invalid when another ingredient has the same name, ignoring case" do
      duplicate = Ingredient.new(ingredient.attributes.except("id").merge("name" => "ARBORIO RICE"))
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "purchase_quantity" do
    it "is valid when greater than 0" do
      ingredient.purchase_quantity = "0.001"
      expect(ingredient).to be_valid
    end

    it "is invalid when 0" do
      ingredient.purchase_quantity = 0
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:purchase_quantity]).to be_present
    end
  end

  describe "purchase_unit" do
    it "is valid for a known unit" do
      ingredient.purchase_unit = "g"
      expect(ingredient).to be_valid
    end

    it "is invalid for an unknown unit" do
      ingredient.purchase_unit = "cup"
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:purchase_unit]).to be_present
    end
  end

  describe "purchase_price_cents" do
    it "is valid when 0" do
      ingredient.purchase_price_cents = 0
      expect(ingredient).to be_valid
    end

    it "is invalid when negative" do
      ingredient.purchase_price_cents = -1
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:purchase_price_cents]).to be_present
    end

    it "is invalid when not a whole number of cents" do
      ingredient.purchase_price_cents = "9.5"
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:purchase_price_cents]).to be_present
    end
  end

  describe "yield_percent" do
    it "is valid at the lower bound of 1" do
      ingredient.yield_percent = 1
      expect(ingredient).to be_valid
    end

    it "is valid at the upper bound of 100" do
      ingredient.yield_percent = 100
      expect(ingredient).to be_valid
    end

    it "is invalid below 1" do
      ingredient.yield_percent = "0.99"
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:yield_percent]).to be_present
    end

    it "is invalid above 100" do
      ingredient.yield_percent = "100.01"
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:yield_percent]).to be_present
    end
  end

  describe "database constraints" do
    it "rejects a negative price even when model validations are skipped" do
      expect {
        Ingredient.insert_all([
          { name: "Bad price", purchase_quantity: 1, purchase_unit: "kg", purchase_price_cents: -100, yield_percent: 100 }
        ])
      }.to raise_error(ActiveRecord::CheckViolation, /ingredients_purchase_price_non_negative/)
    end
  end

  describe "destroying" do
    it "succeeds when no recipe uses the ingredient" do
      expect(ingredients(:sea_salt).destroy).to be_truthy
      expect(Ingredient.exists?(ingredients(:sea_salt).id)).to be(false)
    end

    it "fails with an error when a recipe uses the ingredient" do
      butter = ingredients(:butter)

      expect(butter.destroy).to be(false)
      expect(butter.errors[:base]).to be_present
      expect(Ingredient.exists?(butter.id)).to be(true)
    end

    it "is blocked by the foreign key when model callbacks are skipped" do
      # ON DELETE RESTRICT raises PG::RestrictViolation, which Rails surfaces as a
      # plain StatementInvalid (only NO ACTION's error maps to InvalidForeignKey).
      expect { ingredients(:butter).delete }
        .to raise_error(ActiveRecord::StatementInvalid, /PG::RestrictViolation/)
    end
  end
end
