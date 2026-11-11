class Ingredient < ApplicationRecord
  has_many :recipe_ingredients, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :purchase_quantity, numericality: { greater_than: 0 }
  validates :purchase_unit, inclusion: { in: Units::ALL }
  validates :purchase_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :yield_percent, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }

  def cost_per_base_unit
    usable = Units.to_base_unit(purchase_quantity, purchase_unit) * yield_percent / 100
    purchase_price_cents / usable
  end
end
