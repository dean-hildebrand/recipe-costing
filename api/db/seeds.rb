# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
#
# Idempotent: safe to run `bin/rails db:seed` multiple times.
# Prices are realistic Dutch wholesale (EUR), stored in cents.
# Quantities are strings so they cast straight to BigDecimal (no float drift).

INGREDIENTS = [
  # name,                      purchase_qty, unit,   price_cents, yield_%
  [ "Chicken thigh, boneless",  "2.5",        "kg",   2250,        92 ],
  [ "Beef chuck",               "2",          "kg",   2800,        85 ],
  [ "Salmon fillet, skin-on",   "1",          "kg",   2600,        88 ],
  [ "Unsalted butter",          "1",          "kg",   950,         100 ],
  [ "Whole milk",               "1",          "l",    115,         100 ],
  [ "Heavy cream 35%",          "1",          "l",    480,         100 ],
  [ "Eggs, large",              "30",         "each", 750,         100 ],
  [ "All-purpose flour",        "5",          "kg",   450,         100 ],
  [ "Arborio rice",             "1",          "kg",   390,         100 ],
  [ "Yellow onion",             "5",          "kg",   475,         90 ],
  [ "Garlic",                   "1",          "kg",   850,         85 ],
  [ "Carrots",                  "5",          "kg",   425,         85 ],
  [ "Floury potatoes",          "10",         "kg",   750,         80 ],
  [ "Lemons",                   "20",         "each", 600,         100 ],
  [ "Parmigiano Reggiano",      "1",          "kg",   2400,        95 ],
  [ "Extra virgin olive oil",   "5",          "l",    4200,        100 ],
  [ "Chicken stock",            "5",          "l",    950,         100 ],
  [ "Dry white wine",           "750",        "ml",   550,         100 ],
  [ "Fresh thyme",              "100",        "g",    280,         70 ],
  [ "Sea salt",                 "1",          "kg",   120,         100 ]
].freeze

RECIPES = [
  {
    name: "Parmesan Risotto",
    servings: 4,
    menu_price_cents: 1850,
    notes: "Toast rice in oil, deglaze with wine, add hot stock gradually. Finish with butter and parmesan off the heat.",
    lines: [
      [ "Arborio rice",           "320",  "g" ],
      [ "Chicken stock",          "1.2",  "l" ],
      [ "Dry white wine",         "150",  "ml" ],
      [ "Yellow onion",           "120",  "g" ],
      [ "Unsalted butter",        "60",   "g" ],
      [ "Parmigiano Reggiano",    "80",   "g" ],
      [ "Extra virgin olive oil", "30",   "ml" ],
      [ "Sea salt",               "8",    "g" ]
    ]
  },
  {
    name: "Pan-seared Salmon, Lemon Butter, Crushed Potatoes",
    servings: 2,
    menu_price_cents: 2400,
    notes: "Skin side down until crisp, flip for 1 minute. Crush boiled potatoes with oil and thyme.",
    lines: [
      [ "Salmon fillet, skin-on", "360",  "g" ],
      [ "Floury potatoes",        "500",  "g" ],
      [ "Unsalted butter",        "50",   "g" ],
      [ "Lemons",                 "1",    "each" ],
      [ "Extra virgin olive oil", "20",   "ml" ],
      [ "Fresh thyme",            "5",    "g" ],
      [ "Garlic",                 "10",   "g" ],
      [ "Sea salt",               "6",    "g" ]
    ]
  },
  {
    name: "Braised Beef Chuck with Root Vegetables",
    servings: 6,
    menu_price_cents: 2600,
    notes: "Dredge in flour, sear hard, braise covered at 160C for 3 hours.",
    lines: [
      [ "Beef chuck",             "1.5",  "kg" ],
      [ "Yellow onion",           "300",  "g" ],
      [ "Carrots",                "400",  "g" ],
      [ "Garlic",                 "30",   "g" ],
      [ "Dry white wine",         "375",  "ml" ],
      [ "Chicken stock",          "1",    "l" ],
      [ "Fresh thyme",            "10",   "g" ],
      [ "Extra virgin olive oil", "40",   "ml" ],
      [ "All-purpose flour",      "30",   "g" ],
      [ "Sea salt",               "15",   "g" ]
    ]
  },
  {
    name: "Roast Chicken Thighs, Garlic and Thyme",
    servings: 4,
    menu_price_cents: 1950,
    notes: "Roast with potatoes at 210C for 35 minutes. Squeeze lemon over to finish.",
    lines: [
      [ "Chicken thigh, boneless", "800", "g" ],
      [ "Floury potatoes",         "800", "g" ],
      [ "Garlic",                  "40",  "g" ],
      [ "Fresh thyme",             "8",   "g" ],
      [ "Lemons",                  "1",   "each" ],
      [ "Extra virgin olive oil",  "40",  "ml" ],
      [ "Sea salt",                "10",  "g" ]
    ]
  },
  {
    name: "Pommes Puree",
    servings: 6,
    menu_price_cents: 550,
    notes: "Side dish. Pass potatoes through a ricer, emulsify in cold butter, loosen with warm milk and cream.",
    lines: [
      [ "Floury potatoes",        "1.2",  "kg" ],
      [ "Unsalted butter",        "150",  "g" ],
      [ "Heavy cream 35%",        "200",  "ml" ],
      [ "Whole milk",             "200",  "ml" ],
      [ "Sea salt",               "10",   "g" ]
    ]
  },
  {
    name: "Parmesan and Thyme Gougeres",
    servings: 6,
    menu_price_cents: 750,
    notes: "Snack, 4 pieces per serving. Choux base: cook milk, butter and flour, beat in eggs one at a time, fold in cheese.",
    lines: [
      [ "Whole milk",             "125",  "ml" ],
      [ "Unsalted butter",        "100",  "g" ],
      [ "All-purpose flour",      "150",  "g" ],
      [ "Eggs, large",            "4",    "each" ],
      [ "Parmigiano Reggiano",    "100",  "g" ],
      [ "Fresh thyme",            "3",    "g" ],
      [ "Sea salt",               "3",    "g" ]
    ]
  }
].freeze

ActiveRecord::Base.transaction do
  ingredients = INGREDIENTS.to_h do |name, qty, unit, price_cents, yield_percent|
    ingredient = Ingredient.find_or_initialize_by(name: name)
    ingredient.update!(
      purchase_quantity: qty,
      purchase_unit: unit,
      purchase_price_cents: price_cents,
      yield_percent: yield_percent
    )
    [ name, ingredient ]
  end

  RECIPES.each do |attrs|
    recipe = Recipe.find_or_initialize_by(name: attrs[:name])
    recipe.update!(attrs.slice(:servings, :menu_price_cents, :notes))

    # Rebuild lines so re-seeding reflects edits to this file
    recipe.recipe_ingredients.destroy_all
    attrs[:lines].each do |ingredient_name, qty, unit|
      recipe.recipe_ingredients.create!(
        ingredient: ingredients.fetch(ingredient_name), # raises on typos
        quantity: qty,
        unit: unit
      )
    end
  end
end

puts "Seeded #{Ingredient.count} ingredients and #{Recipe.count} recipes."
