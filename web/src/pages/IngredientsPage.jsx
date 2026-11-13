import { useState, useEffect } from "react"
import { getIngredients } from "../api"
import IngredientsTable from "../components/IngredientsTable"
import IngredientForm from "../components/IngredientForm"

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

  const handleIngredientCreated = (newIngredient) => {
    setIngredients(
      (prev) =>
        [...prev, newIngredient].sort((a, b) => a.name.localeCompare(b.name)), // sort to add in correct position in the table
    )
  }

  if (error) return <p>Couldn't load ingredients: {error.message}</p>
  if (!ingredients) return <p>Loading...</p>

  return (
    <>
      <IngredientForm onSaved={handleIngredientCreated} />
      <IngredientsTable ingredients={ingredients} />
    </>
  )
}

export default IngredientsPage
