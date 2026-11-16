import { useState, useEffect } from "react"
import { deleteIngredient, getIngredients } from "../api"
import IngredientsTable from "../components/IngredientsTable"
import IngredientForm from "../components/IngredientForm"

const IngredientsPage = () => {
  const [ingredients, setIngredients] = useState(null)
  const [error, setError] = useState(null)
  const [deleteError, setDeleteError] = useState(null)

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

  const handleIngredientDelete = async (ingredient) => {
    const { id } = ingredient
    setDeleteError(null)
    try {
      await deleteIngredient(id)
      setIngredients((prev) => prev.filter((i) => i.id !== id))
    } catch (e) {
      const messages = Object.values(e.errors ?? {}).flat()
      setDeleteError({
        id,
        message: messages.length
          ? messages.join(", ")
          : `Couldn't delete ${ingredient.name} (${e.status ?? e.message})`,
      })
    }
  }

  if (error) return <p>Couldn't load ingredients: {error.message}</p>
  if (!ingredients) return <p>Loading...</p>

  return (
    <>
      <IngredientForm onSaved={handleIngredientCreated} />
      <IngredientsTable
        ingredients={ingredients}
        handleDelete={handleIngredientDelete}
        deleteError={deleteError}
      />
    </>
  )
}

export default IngredientsPage
