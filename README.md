# Recipe Costing

Recipe cost and yield calculator. Track ingredient purchase prices, build recipes from them, and see plate cost, food cost % and margin per dish.

- `api/`: Rails 8.1 API, PostgreSQL 18
- `web/`: React + TypeScript (Vite)

## Setup

```bash
docker compose up -d
cd api
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

## Data model

| Table | Purpose |
|---|---|
| `ingredients` | What you buy: purchase quantity, unit, price, usable yield after trim |
| `recipes` | What you sell: servings and menu price |
| `recipe_ingredients` | How much of each ingredient a recipe uses, in any compatible unit |

## API

All endpoints are JSON, under `/api/v1`.

```
GET    /api/v1/units                    → unit → dimension map, for the frontend dropdowns

GET    /api/v1/ingredients
GET    /api/v1/ingredients/:id
POST   /api/v1/ingredients
PATCH  /api/v1/ingredients/:id
DELETE /api/v1/ingredients/:id          → 422 if used by a recipe

GET    /api/v1/recipes                  → list with batch/plate cost, food_cost_percent, margin_cents
GET    /api/v1/recipes/:id              → recipe + lines (each with its ingredient and line cost_cents)
POST   /api/v1/recipes                  → accepts nested lines
PATCH  /api/v1/recipes/:id              → creates/updates/removes lines in one request
DELETE /api/v1/recipes/:id

POST   /api/v1/recipes/preview          → computes costs for an unsaved recipe, saves nothing
```

### Conventions

- **Money is integer cents**, in fields ending `_cents`. The client formats it for display.
- **Decimals are strings**: `quantity`, `purchase_quantity`, `yield_percent` and `food_cost_percent` look like `"1.2"`. The client sends them back as strings too.
- **Request bodies are wrapped** in a root key (`{ "recipe": { ... } }`, `{ "ingredient": { ... } }`). Responses aren't wrapped.
- **Costs are computed on read** every time a recipe is serialised. Nothing is cached.
- **Line `cost_cents` is rounded for display only.** Totals are calculated from the unrounded line costs, so the rounded lines may not add up exactly to `batch_cost_cents`.

### Errors

Every error uses one shape:

```json
{ "errors": { "field": ["message"] } }
```

| Status | When | Example |
|---|---|---|
| 422 | Validation failed | `{ "errors": { "servings": ["must be greater than 0"] } }` |
| 422 | Invalid nested line | `{ "errors": { "recipe_ingredients[1].unit": ["ml can't be used for Arborio rice, which is bought in kg"] } }` |
| 422 | Same ingredient twice | `{ "errors": { "recipe_ingredients": ["can't include the same ingredient twice"] } }` |
| 422 | Ingredient in use | `{ "errors": { "base": ["Cannot delete record because dependent recipe ingredients exist"] } }` |
| 400 | Missing root key | `{ "errors": { "base": ["param is missing or the value is empty or invalid: ingredient"] } }` |
| 404 | Unknown id | `{ "errors": { "base": ["Recipe not found"] } }` |

Line errors are keyed by the line's position in the submitted array (`index_errors: :nested_attributes_order`), so the form can show each error next to the right row.

### `GET /api/v1/recipes/:id`

```
GET /api/v1/recipes/1
```

```json
{
  "id": 1,
  "name": "Parmesan Risotto",
  "servings": 4,
  "menu_price_cents": 1850,
  "notes": "Toast rice in oil, deglaze with wine, add hot stock gradually. Finish with butter and parmesan off the heat.",
  "batch_cost_cents": 761,
  "plate_cost_cents": 190,
  "food_cost_percent": "10.3",
  "margin_cents": 1660,
  "recipe_ingredients": [
    { "id": 1, "ingredient_id": 9,  "ingredient": { "id": 9,  "name": "Arborio rice",           "purchase_unit": "kg" }, "quantity": "320.0", "unit": "g",  "cost_cents": 125 },
    { "id": 2, "ingredient_id": 17, "ingredient": { "id": 17, "name": "Chicken stock",          "purchase_unit": "l"  }, "quantity": "1.2",   "unit": "l",  "cost_cents": 228 },
    { "id": 3, "ingredient_id": 18, "ingredient": { "id": 18, "name": "Dry white wine",         "purchase_unit": "ml" }, "quantity": "150.0", "unit": "ml", "cost_cents": 110 },
    { "id": 4, "ingredient_id": 10, "ingredient": { "id": 10, "name": "Yellow onion",           "purchase_unit": "kg" }, "quantity": "120.0", "unit": "g",  "cost_cents": 13 },
    { "id": 5, "ingredient_id": 4,  "ingredient": { "id": 4,  "name": "Unsalted butter",        "purchase_unit": "kg" }, "quantity": "60.0",  "unit": "g",  "cost_cents": 57 },
    { "id": 6, "ingredient_id": 15, "ingredient": { "id": 15, "name": "Parmigiano Reggiano",    "purchase_unit": "kg" }, "quantity": "80.0",  "unit": "g",  "cost_cents": 202 },
    { "id": 7, "ingredient_id": 16, "ingredient": { "id": 16, "name": "Extra virgin olive oil", "purchase_unit": "l"  }, "quantity": "30.0",  "unit": "ml", "cost_cents": 25 },
    { "id": 8, "ingredient_id": 20, "ingredient": { "id": 20, "name": "Sea salt",               "purchase_unit": "kg" }, "quantity": "8.0",   "unit": "g",  "cost_cents": 1 }
  ]
}
```

`food_cost_percent` and `margin_cents` are `null` when the recipe has no menu price.

### `PATCH /api/v1/recipes/:id`

Lines use Rails nested attributes. A line with an `id` is updated, a line with `id` and `"_destroy": true` is removed, and a line without an `id` is created. Lines that aren't in the array stay as they are.

```json
{
  "recipe": {
    "servings": 4,
    "recipe_ingredients_attributes": [
      { "id": 1, "quantity": "350" },
      { "id": 8, "_destroy": true },
      { "ingredient_id": 19, "quantity": "5", "unit": "g" }
    ]
  }
}
```

The response is the updated recipe, in the same shape as `GET /api/v1/recipes/:id`. `POST /api/v1/recipes` takes the same body without line ids.

### `POST /api/v1/recipes/preview`

This takes the same body as `POST /api/v1/recipes`, builds the recipe in memory, and returns the same shape as `GET /api/v1/recipes/:id` with `id: null`. Nothing is saved.

- **Don't send line ids, and leave out lines marked `_destroy`.** The recipe is built with `Recipe.new`, and nested attributes on a new record can't look up existing line ids.
- **Every validation runs except `name`.** Previewing a recipe you're editing would otherwise fail the uniqueness check. Servings and lines still have to be valid, because the costs can't be computed without them (servings of 0 would divide by zero). Invalid input returns 422 in the usual error shape.

### `GET /api/v1/units`

```json
{ "g": "mass", "kg": "mass", "ml": "volume", "l": "volume", "each": "count" }
```

This comes straight from `Units::DIMENSIONS`, so the unit list only exists in Ruby and the database. The frontend doesn't keep its own copy.

### Why these wire formats

- **Integer cents, not `7.61` or `"7.61"`.** JSON numbers become IEEE doubles in JavaScript, and 7.61 can't be represented exactly as a double. Any arithmetic on it in the browser (summing lines, for example) can drift. A string like `"7.61"` avoids that, but the client then has to parse it before it can do anything with it, and the server ends up choosing the display format. Integer cents are exact in both languages, and the client formats them with `Intl.NumberFormat` in the user's locale.
- **Decimals stay strings.** That's Rails' default for `BigDecimal`, and it keeps full precision across the wire. The client only needs these values to fill form inputs, which hold strings anyway, and to display them. It never does cost maths with them, because `/preview` does that on the server. Converting them to JSON numbers would send exact values through a float on both ends for no benefit.
- **Nested attributes for lines.** `accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true` handles create, update and delete of lines in one transaction and runs the line validations. Its `{ id?, ingredient_id, quantity, unit, _destroy? }` shape is exactly what the editor form keeps in state, so saving means sending the form as it is. The cost is a Rails-flavoured key name (`recipe_ingredients_attributes`) in the public API.

## Decisions & trade-offs

### Money and quantities
- **Money is stored as integer cents and quantities as `decimal`.** Floats never touch the cost path, so cost totals don't drift through rounding errors.
- **Ingredients have a `yield_percent`** to account for trim loss (a kilo of onions gives about 900 g usable). Cost is calculated on the usable amount, not the purchased amount.

### Integrity in the database, not just the models
- **Every rule that can be expressed as a constraint is one.** That covers `NOT NULL`, positive quantities, a 1 to 100 yield range, allowed units, and unique names using `citext` so "Garlic" and "garlic" can't both exist. Model validations give friendly error messages, and the database guarantees the rules even for `insert_all`, the console and raw SQL.
- **The unit list exists in two places, the check constraint and `lib/units.rb`.** Adding a unit means writing a migration. I accepted that cost because it stops bad data from getting in through any path that skips model validations.
- **The unit compatibility check lives in the model, not the database.** Whether a recipe line's unit fits its ingredient's purchase unit (no grams of something bought by the litre) depends on a column in another table. Postgres check constraints can't read across tables. A trigger could enforce it, but that hides business logic in the database, so it's a validation on `RecipeIngredient` instead.

### Foreign keys
- **Deleting a recipe cascades to its lines.** They have no meaning without it.
- **Deleting an ingredient that a recipe uses is restricted.** You have to remove it from the recipes first, so recipe costs never silently change.

### Indexes
- **There's no standalone index on `recipe_ingredients.recipe_id`.** The composite unique index on `[recipe_id, ingredient_id]` starts with `recipe_id`, so it already serves lookups by recipe. A second index would only add write cost.
- **`ingredient_id` keeps its own index** for "which recipes use this ingredient" queries and the `RESTRICT` check on delete.

### Why PostgreSQL over SQLite
- SQLite has no exact decimal type, so values with a fractional part are stored as floating point. That defeats the money and quantity decisions above.
- `citext` and the Postgres features used in follow-up projects (full-text search, partial indexes, `EXPLAIN ANALYZE`) aren't available in SQLite.

### Repo layout
- **This is a monorepo with a separate API and SPA** instead of Rails views. It shows a clean JSON API boundary, at the cost of two apps to run and deploy. Vite proxies `/api` to Rails in development, so no CORS setup is needed locally.
