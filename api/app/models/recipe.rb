class Recipe < ApplicationRecord
  # DB constraints deletes recipe's lines when recipe is deleted
  has_many :recipe_ingredients
  has_many :ingredients, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
  validates :menu_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  def batch_cost_cents
    batch_cost.round
  end

  def plate_cost_cents
    plate_cost.round
  end

  def food_cost_percent
    menu_price_cents&.positive? ? (plate_cost / menu_price_cents * 100).round(1) : nil
  end

  def margin_cents
    menu_price_cents && (menu_price_cents - plate_cost).round
  end

  def plate_cost_cents
    (batch_cost_cents.to_f / servings).round
  end


  private

  def batch_cost
    recipe_ingredients.sum(BigDecimal("0"), &:cost)
  end

  def plate_cost
    batch_cost / servings
  end
end
