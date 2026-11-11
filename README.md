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
