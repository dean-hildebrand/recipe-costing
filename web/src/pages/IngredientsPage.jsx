import { useState, useEffect } from "react"
import { getIngredients } from "../api"
import IngredientsTable from "../components/IngredientsTable"

const IngredientsPage = () => {
  const [ingredients, setIngredients] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    const getIngredientsCall = async () => {
      try {
        const results = await getIngredients()
        setIngredients(results)
      } catch (e) {
        setError(e)
      }
    }
    getIngredientsCall()
  }, [])

  if (error) return <p>Couldn't load ingredients: {error.message}</p>
  if (!ingredients) return <p>Loading...</p>

  return <IngredientsTable ingredients={ingredients} />
}

export default IngredientsPage
