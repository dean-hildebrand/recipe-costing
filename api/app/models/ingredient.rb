class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :purchase_quantity, numericality: { greater_than: 0 }
  validates :purchase_unit, inclusion: { in: Units::ALL }
  validates :purchase_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :yield_percent, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }
  validate :unit_dimension_unchanged_while_used, on: :update

  def cost_per_base_unit
    usable = Units.to_base_unit(purchase_quantity, purchase_unit) * yield_percent / 100
    purchase_price_cents / usable
  end

  private

  # Recipe lines are checked against the ingredient's unit only when the line is saved.
  # Changing kg -> each leaves those lines miscosted (grams × cents-per-each)

  def unit_dimension_unchanged_while_used
    return unless will_save_change_to_purchase_unit? && Units::ALL.include?(purchase_unit)

    old_unit = purchase_unit_in_database
    return if Units.compatible?(old_unit, purchase_unit)

    recipe_names = recipes.distinct.order(:name).pluck(:name)
    return if recipe_names.empty?

    errors.add(:purchase_unit, "can't change from #{old_unit} to #{purchase_unit} while used in #{recipe_names.join(', ')}")
  end
end
