import { useState, useEffect } from "react"
import { getRecipe, getIngredients, getUnits } from "../../api"
import { centsToEuros } from "../../format"

const EMPTY_FORM = {
  name: "",
  servings: "",
  menu_price: "",
  notes: "",
  lines: [],
}

const toFormState = ({
  name,
  servings,
  menu_price_cents,
  notes,
  recipe_ingredients,
}) => ({
  name,
  servings,
  menu_price: centsToEuros(menu_price_cents),
  notes: notes ?? "",
  lines: recipe_ingredients.map(({ id, ingredient_id, quantity, unit }) => ({
    key: crypto.randomUUID(),
    id,
    ingredient_id,
    quantity,
    unit,
  })),
})

const RecipeEditor = ({ recipeId, onBack }) => {
  const [ingredients, setIngredients] = useState(null)
  const [units, setUnits] = useState(null)
  const [recipe, setRecipe] = useState(null)
  const [error, setError] = useState(null)
  const [recipeFormData, setRecipeFormData] = useState(EMPTY_FORM)
  const { name, servings, menu_price, notes, lines } = recipeFormData

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
        setRecipeFormData(toFormState(recipe))
      } catch (error) {
        setError(error)
      }
    }
    load()
  }, [recipeId])

  const handleChange = (e) => {
    const { name, value } = e.target
    setRecipeFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleLineChange = (key, e) => {
    const { name, value } = e.target
    setRecipeFormData((prev) => ({
      ...prev,
      lines: prev.lines.map((line) =>
        line.key === key ? { ...line, [name]: value } : line,
      ),
    }))
  }

  const removeHandler = (key) => {
    setRecipeFormData((prev) => ({
      ...prev,
      lines: prev.lines.flatMap((line) => {
        if (key === line.key) {
          if (line.ingredient_id) {
            return [{ ...line, _destroy: true }]
          } else {
            return []
          }
        }
        return [line]
      }),
    }))
  }

  if (error) return <p>Couldn't load recipe: {error.message}</p>
  if (!recipe) return <p>Loading...</p>

  return (
    <>
      <button onClick={onBack}>Back</button>
      <h2>{recipe.name}</h2>
      <form>
        <label>
          Recipe Name:
          <input name="name" value={name} onChange={handleChange} />
        </label>
        <label>
          Servings:
          <input name="servings" value={servings} onChange={handleChange} />
        </label>
        <label>
          Menu price:
          <input name="menu_price" value={menu_price} onChange={handleChange} />
        </label>
        <label>
          Notes:
          <input name="notes" value={notes} onChange={handleChange} />
        </label>
        <label>
          Ingredients:
          {lines
            .filter((line) => line._destroy != true)
            .map(({ key, ingredient_id, quantity, unit }) => (
              <div key={key}>
                <select
                  name="ingredient_id"
                  value={ingredient_id}
                  onChange={(e) => handleLineChange(key, e)}
                >
                  {ingredients.map((i) => (
                    <option key={i.id} value={i.id}>
                      {i.name}
                    </option>
                  ))}
                </select>
                <input
                  name="quantity"
                  value={quantity}
                  onChange={(e) => handleLineChange(key, e)}
                />
                <select
                  name="unit"
                  value={unit}
                  onChange={(e) => handleLineChange(key, e)}
                >
                  {Object.keys(units).map((u) => (
                    <option key={u}>{u}</option>
                  ))}
                </select>
                <button
                  className="danger"
                  type="button"
                  onClick={() => removeHandler(key)}
                >
                  x
                </button>
              </div>
            ))}
        </label>
      </form>
    </>
  )
}

export default RecipeEditor
