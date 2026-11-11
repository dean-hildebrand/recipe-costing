class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.citext  :name,                 null: false
      t.decimal :purchase_quantity,    null: false, precision: 10, scale: 3
      t.string  :purchase_unit,        null: false
      t.integer :purchase_price_cents, null: false
      t.decimal :yield_percent,        null: false, precision: 5, scale: 2, default: 100

      t.timestamps

      t.index :name, unique: true

      t.check_constraint "purchase_quantity > 0",               name: "ingredients_purchase_quantity_positive"
      t.check_constraint "purchase_price_cents >= 0",           name: "ingredients_purchase_price_non_negative"
      t.check_constraint "yield_percent BETWEEN 1 AND 100",     name: "ingredients_yield_percent_range"
      t.check_constraint "purchase_unit IN ('g', 'kg', 'ml', 'l', 'each')", name: "ingredients_purchase_unit_allowed"
    end
  end
end
