class Recipe < ApplicationRecord
  # DB constraints deletes recipe's lines when recipe is deleted
  has_many :recipe_ingredients
  has_many :ingredients, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
  validates :menu_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
