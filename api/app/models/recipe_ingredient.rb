class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :ingredient

  validates :ingredient_id, uniqueness: { scope: :recipe_id, message: "is already in this recipe" }
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit, inclusion: { in: Units::ALL }
  validate :unit_compatible_with_ingredient

  private

  def unit_compatible_with_ingredient
    return if ingredient.nil? || !Units::ALL.include?(unit)
    return if Units.compatible?(unit, ingredient.purchase_unit)

    errors.add(:unit, "#{unit} can't be used for #{ingredient.name}, which is bought in #{ingredient.purchase_unit}")
  end
end
