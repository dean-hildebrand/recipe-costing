import { useState, useEffect } from "react"
import { getRecipe, getIngredients, getUnits, previewRecipe } from "../../api"
import { centsToEuros, formatCents, eurosToCents } from "../../format"

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

const previewableLines = (lines) => {
  const newLines = lines.filter(
    (line) =>
      line._destroy != true &&
      line.ingredient_id != "" &&
      line.quantity != "" &&
      line.unit != "",
  )
  return newLines
}

const toPayload = ({ lines, menu_price, ...rest }) => ({
  ...rest,
  menu_price_cents: eurosToCents(menu_price),
  recipe_ingredients_attributes: previewableLines(lines).map(
    ({ ingredient_id, quantity, unit }) => ({
      ingredient_id,
      quantity,
      unit,
    }),
  ),
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
  const [previewError, setPreviewError] = useState({})
  const [recipeFormData, setRecipeFormData] = useState(EMPTY_FORM)
  const { name, servings, menu_price, notes, lines } = recipeFormData
  const [preview, setPreview] = useState(null)

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
        setPreview(recipe)
        setRecipeFormData(toFormState(recipe))
      } catch (error) {
        setError(error)
      }
    }
    load()
  }, [recipeId])

  useEffect(() => {
    if (!recipe) return
    const updatePreviewCosts = async () => {
      try {
        const payload = toPayload(recipeFormData)
        const previewResult = await previewRecipe(payload)
        setPreview(previewResult)
        setPreviewError({})
      } catch (error) {
        // 422s carry { field: [messages] }; network errors and 404s don't
        setPreviewError(error.errors ?? { base: [error.message] })
      }
    }
    const timer = setTimeout(() => {
      updatePreviewCosts()
    }, 300)
    return () => clearTimeout(timer)
  }, [recipe, recipeFormData])

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

  // Nested line errors come back as "recipe_ingredients" or
  // "recipe_ingredients.quantity"
  const lineErrors = Object.entries(previewError)
    .filter(([field]) => field.startsWith("recipe_ingredients"))
    .flatMap(([, messages]) => messages)
  const hasPreviewError = Object.keys(previewError).length > 0

  if (error) return <p>Couldn't load recipe: {error.message}</p>
  if (!recipe) return <p>Loading...</p>

  return (
    <>
      <button onClick={onBack}>Back</button>
      <h2>{recipe.name}</h2>
      {previewError.base && (
        <p className="field-error">
          Couldn't update costs: {previewError.base.join(", ")}
        </p>
      )}
      {preview && (
        <div className={hasPreviewError ? "totals stale" : "totals"}>
          <p>
            Batch cost:
            <span className="totals-item">
              {formatCents(preview.batch_cost_cents)}
            </span>
          </p>
          <p>
            Plate cost:
            <span className="totals-item">
              {formatCents(preview.plate_cost_cents)}
            </span>
          </p>
          <p>
            Foodcost percentage:
            <span className="totals-item">
              {preview.food_cost_percent
                ? preview.food_cost_percent + "%"
                : "-"}
            </span>
          </p>
          <p>
            Margin:
            <span className="totals-item">
              {formatCents(preview.margin_cents)}
            </span>
          </p>
        </div>
      )}
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
          {previewError.servings && (
            <p className="field-error">{previewError.servings.join(", ")}</p>
          )}
          <label>
            Menu price:
            <input
              name="menu_price"
              value={menu_price}
              onChange={handleChange}
            />
          </label>
          {previewError.menu_price_cents && (
            <p className="field-error">
              {previewError.menu_price_cents.join(", ")}
            </p>
          )}
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
          {lineErrors.map((message) => (
            <p className="field-error" key={message}>
              {message}
            </p>
          ))}
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
