import { useState, useEffect } from "react"
import { getRecipes } from "./api"
import RecipesTable from "./components/RecipesTable"

function App() {
  const [recipes, setRecipes] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const getRecipeCall = async () => {
      try {
        const results = await getRecipes()
        setRecipes(results)
      } catch (e) {
        setError(e)
      }
    }
    getRecipeCall()
  }, [])

  if (error) return <p>Couldn't load recipes: {error.message}</p>
  if (!recipes) return <p>Loading...</p>

  return <RecipesTable recipes={recipes} />
}

export default App
