import { useState, useEffect } from "react"
import { getRecipe, getIngredients, getUnits } from "../../api"

const RecipeEditor = ({ recipeId, onBack }) => {
  const [ingredients, setIngredients] = useState(null)
  const [units, setUnits] = useState(null)
  const [recipe, setRecipe] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const load = async () => {
      try {
        const [ingredients, units, recipe] = await Promise.all([
          getIngredients(),
          getUnits(),
          getRecipe(recipeId),
        ])
        setIngredients(ingredients)
        setUnits(units)
        setRecipe(recipe)
      } catch (error) {
        setError(error)
      }
    }
    load()
  }, [recipeId])

  if (error) return <p>Couldn't load recipe: {error.message}</p>
  if (!recipe) return <p>Loading...</p>

  return (
    <>
      <button onClick={onBack}>Back</button>
      <h2>{recipe.name}</h2>
      <pre>{JSON.stringify(recipe)}</pre>
    </>
  )
}

export default RecipeEditor
