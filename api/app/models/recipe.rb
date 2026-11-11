class Recipe < ApplicationRecord
  # DB constraint (ON DELETE CASCADE) deletes a recipe's lines when the recipe is deleted.
  # index_errors keys line errors by their position in the submitted
  # recipe_ingredients_attributes array, e.g. "recipe_ingredients[1].unit".
  has_many :recipe_ingredients, -> { order(:id) }, index_errors: :nested_attributes_order
  has_many :ingredients, through: :recipe_ingredients

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true

  validates :name, presence: true, uniqueness: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
  validates :menu_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :ingredients_not_repeated

  # Lines that will exist after saving: skips lines marked with _destroy.
  def costed_lines
    recipe_ingredients.reject(&:marked_for_destruction?)
  end

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

  private

  def batch_cost
    costed_lines.sum(BigDecimal("0"), &:cost)
  end

  def plate_cost
    batch_cost / servings
  end

  # The unique index on [recipe_id, ingredient_id] would raise RecordNotUnique (a 500)
  # if one request adds the same ingredient twice. Catch it as a validation instead.
  def ingredients_not_repeated
    ids = costed_lines.map(&:ingredient_id).compact
    return if ids.uniq.size == ids.size

    errors.add(:recipe_ingredients, "can't include the same ingredient twice")
  end
end
