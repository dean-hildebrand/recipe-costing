import RecipeTableRow from "./RecipeTableRow"
const RecipesTable = ({ recipes, onSelectRecipe }) => {
  return (
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Plate cost</th>
          <th>Food cost %</th>
        </tr>
      </thead>
      <tbody>
        {recipes.map((recipe) => (
          <RecipeTableRow
            key={recipe.id}
            recipe={recipe}
            onSelectRecipe={onSelectRecipe}
          />
        ))}
      </tbody>
    </table>
  )
}

export default RecipesTable
