# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_10_154300) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "ingredients", force: :cascade do |t|
    t.citext "name", null: false
    t.decimal "purchase_quantity", precision: 10, scale: 3, null: false
    t.string "purchase_unit", null: false
    t.integer "purchase_price_cents", null: false
    t.decimal "yield_percent", precision: 5, scale: 2, default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredients_on_name", unique: true
    t.check_constraint "purchase_price_cents >= 0", name: "ingredients_purchase_price_non_negative"
    t.check_constraint "purchase_quantity > 0::numeric", name: "ingredients_purchase_quantity_positive"
    t.check_constraint "purchase_unit::text = ANY (ARRAY['g'::character varying, 'kg'::character varying, 'ml'::character varying, 'l'::character varying, 'each'::character varying]::text[])", name: "ingredients_purchase_unit_allowed"
    t.check_constraint "yield_percent >= 1::numeric AND yield_percent <= 100::numeric", name: "ingredients_yield_percent_range"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "ingredient_id", null: false
    t.decimal "quantity", precision: 10, scale: 3, null: false
    t.string "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_ingredients_on_recipe_id_and_ingredient_id", unique: true
    t.check_constraint "quantity > 0::numeric", name: "recipe_ingredients_quantity_positive"
    t.check_constraint "unit::text = ANY (ARRAY['g'::character varying, 'kg'::character varying, 'ml'::character varying, 'l'::character varying, 'each'::character varying]::text[])", name: "recipe_ingredients_unit_allowed"
  end

  create_table "recipes", force: :cascade do |t|
    t.citext "name", null: false
    t.integer "servings", default: 1, null: false
    t.integer "menu_price_cents"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_recipes_on_name", unique: true
    t.check_constraint "menu_price_cents IS NULL OR menu_price_cents >= 0", name: "recipes_menu_price_non_negative"
    t.check_constraint "servings > 0", name: "recipes_servings_positive"
  end

  add_foreign_key "recipe_ingredients", "ingredients", on_delete: :restrict
  add_foreign_key "recipe_ingredients", "recipes", on_delete: :cascade
end
