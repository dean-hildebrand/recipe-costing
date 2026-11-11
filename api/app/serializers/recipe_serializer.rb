# Plain Ruby serializer: no gem, just hashes
module RecipeSerializer
  module_function

  def summary(recipe)
    recipe.as_json(only: %i[id name servings menu_price_cents]).merge(costs(recipe))
  end

  def detail(recipe)
    recipe.as_json(only: %i[id name servings menu_price_cents notes])
          .merge(costs(recipe))
          .merge("recipe_ingredients" => recipe.costed_lines.map { |line| line(line) })
  end

  def costs(recipe)
    {
      "batch_cost_cents" => recipe.batch_cost_cents,
      "plate_cost_cents" => recipe.plate_cost_cents,
      "food_cost_percent" => recipe.food_cost_percent&.to_s,
      "margin_cents" => recipe.margin_cents
    }
  end

  def line(line)
    {
      "id" => line.id,
      "ingredient_id" => line.ingredient_id,
      "ingredient" => line.ingredient.as_json(only: %i[id name purchase_unit]),
      "quantity" => line.quantity.to_s,
      "unit" => line.unit,
      "cost_cents" => line.cost.round # display only; totals use unrounded costs
    }
  end
end
