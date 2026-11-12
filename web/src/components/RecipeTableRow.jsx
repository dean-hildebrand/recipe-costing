import { formatCents } from "../format"

const RecipeTableRow = ({ recipe }) => {
  return (
    <tr>
      <td>{recipe.name}</td>
      <td>{formatCents(recipe.plate_cost_cents)}</td>
      <td>{recipe.food_cost_percent ? `${recipe.food_cost_percent}%` : "—"}</td>
    </tr>
  )
}

export default RecipeTableRow
