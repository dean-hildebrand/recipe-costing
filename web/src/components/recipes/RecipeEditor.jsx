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

const getIngredient = (ingredientId, ingredients) => {
  if (!ingredientId) return null
  const ingredient = ingredients.find(
    (ingredient) => Number(ingredientId) === ingredient.id,
  )
  return ingredient
}

const compatibleUnits = (ingredientId, ingredients, units) => {
  const ingredient = getIngredient(ingredientId, ingredients)
  const dimension = units[ingredient?.purchase_unit]
  const matchingUnits = Object.entries(units).filter(([, dim]) => {
    return dim === dimension
  })
  return matchingUnits.map(([name]) => name)
}

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
    const newIngredient =
      name === "ingredient_id" ? getIngredient(value, ingredients) : null

    setRecipeFormData((prev) => ({
      ...prev,
      lines: prev.lines.map((line) =>
        line.key === key
          ? name === "ingredient_id"
            ? {
                ...line,
                ingredient_id: newIngredient?.id ?? "",
                unit: newIngredient?.purchase_unit ?? "",
              }
            : { ...line, [name]: value }
          : line,
      ),
    }))
  }

  const removeHandler = (key) => {
    setRecipeFormData((prev) => ({
      ...prev,
      lines: prev.lines.flatMap((line) => {
        if (key === line.key) {
          if (line.id) {
            return [{ ...line, _destroy: true }]
          } else {
            return []
          }
        }
        return [line]
      }),
    }))
  }

  const handleAddLine = () => {
    const newLine = {
      key: crypto.randomUUID(),
      ingredient_id: "",
      quantity: "",
      unit: "",
    }
    setRecipeFormData((prev) => ({
      ...prev,
      lines: [...prev.lines, newLine],
    }))
  }

  if (error) return <p>Couldn't load recipe: {error.message}</p>
  if (!recipe) return <p>Loading...</p>

  return (
    <>
      <button onClick={onBack}>Back</button>
      <h2>{recipe.name}</h2>
      <form className="recipe">
        <div className="main-recipe">
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
            <input
              name="menu_price"
              value={menu_price}
              onChange={handleChange}
            />
          </label>
          <label>
            Notes:
            <textarea
              name="notes"
              value={notes}
              rows={(notes.length + 10) / 35}
              onChange={handleChange}
            />
          </label>
        </div>
        <div className="recipe-ingredients">
          <span className="field-heading">Ingredients:</span>
          {lines
            .filter((line) => line._destroy != true)
            .map(({ key, ingredient_id, quantity, unit }) => (
              <div className="ingredient-row" key={key}>
                <select
                  name="ingredient_id"
                  value={ingredient_id}
                  onChange={(e) => handleLineChange(key, e)}
                >
                  <option value="">Choose ingredient...</option>
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
                  <option value="">Choose unit...</option>
                  {compatibleUnits(ingredient_id, ingredients, units).map(
                    (u) => (
                      <option key={u}>{u}</option>
                    ),
                  )}
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
          <button className="add-line" type="button" onClick={handleAddLine}>
            Add Ingredient
          </button>
        </div>
      </form>
    </>
  )
}

export default RecipeEditor
