class CreateRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe,     null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :ingredient, null: false,               foreign_key: { on_delete: :restrict }
      t.decimal    :quantity,   null: false, precision: 10, scale: 3
      t.string     :unit,       null: false

      t.timestamps

      t.index %i[recipe_id ingredient_id], unique: true

      t.check_constraint "quantity > 0",                           name: "recipe_ingredients_quantity_positive"
      t.check_constraint "unit IN ('g', 'kg', 'ml', 'l', 'each')", name: "recipe_ingredients_unit_allowed"
    end
  end
end
