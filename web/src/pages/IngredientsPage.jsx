import { useState, useEffect } from "react"
import { deleteIngredient, getIngredients, getUnits } from "../api"
import IngredientsTable from "../components/IngredientsTable"
import IngredientForm from "../components/IngredientForm"

const IngredientsPage = () => {
  const [ingredients, setIngredients] = useState(null)
  const [error, setError] = useState(null)
  const [deleteError, setDeleteError] = useState(null)
  const [editing, setEditing] = useState(null)
  const [successMessage, setSuccessMessage] = useState(null)
  const [units, setUnits] = useState(null)

  useEffect(() => {
    const load = async () => {
      try {
        const [ingredients, units] = await Promise.all([
          getIngredients(),
          getUnits(),
        ])
        setIngredients(ingredients)
        setUnits(units)
      } catch (e) {
        setError(e)
      }
    }
    load()
  }, [])

  const handleIngredientActions = (ingredient) => {
    if (!editing) {
      setIngredients(
        (prev) =>
          [...prev, ingredient].sort((a, b) => a.name.localeCompare(b.name)), // sort to add in correct position in the table
      )
    } else {
      setIngredients((prev) =>
        prev.map((i) => (i.id === ingredient.id ? ingredient : i)),
      )
      setEditing(null)
    }
  }

  const handleIngredientEdit = (ingredient) => {
    setEditing(ingredient)
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
  if (!ingredients || !units) return <p>Loading...</p>

  return (
    <>
      <IngredientForm
        onSaved={handleIngredientActions}
        ingredientToEdit={editing}
        successMessage={successMessage}
        setSuccessMessage={setSuccessMessage}
        units={units}
        key={editing?.id ?? "new"}
      />
      <IngredientsTable
        ingredients={ingredients}
        handleDelete={handleIngredientDelete}
        deleteError={deleteError}
        handleEdit={handleIngredientEdit}
      />
    </>
  )
}

export default IngredientsPage
