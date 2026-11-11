class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.citext  :name,             null: false
      t.integer :servings,         null: false, default: 1
      t.integer :menu_price_cents  # nullable: sub-recipes (stocks, sauces) aren't sold on their own
      t.text    :notes

      t.timestamps

      t.index :name, unique: true

      t.check_constraint "servings > 0",                                      name: "recipes_servings_positive"
      t.check_constraint "menu_price_cents IS NULL OR menu_price_cents >= 0", name: "recipes_menu_price_non_negative"
    end
  end
end
