import { useState, useEffect } from "react"
import { getRecipes } from "../api"
import RecipesTable from "../components/recipes/RecipesTable"

const RecipePage = ({ onSelectRecipe }) => {
  const [recipes, setRecipes] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const getRecipesCall = async () => {
      try {
        const results = await getRecipes()
        setRecipes(results)
      } catch (e) {
        setError(e)
      }
    }
    getRecipesCall()
  }, [])

  if (error) return <p>Couldn't load recipes: {error.message}</p>
  if (!recipes) return <p>Loading...</p>

  return <RecipesTable recipes={recipes} onSelectRecipe={onSelectRecipe} />
}

export default RecipePage
