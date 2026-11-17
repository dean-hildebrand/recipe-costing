import { useState, useEffect } from "react"
import { createIngredient, updateIngredient } from "../../api"
import { eurosToCents, centsToEuros } from "../../format"

const EMPTY_FORM = {
  name: "",
  purchase_unit: "g",
  purchase_quantity: "",
  purchase_price: "",
  yield_percent: "100",
}

const toFormData = ({
  name,
  purchase_unit,
  purchase_price_cents,
  purchase_quantity,
  yield_percent,
}) => ({
  name,
  purchase_unit,
  purchase_price: centsToEuros(purchase_price_cents),
  purchase_quantity,
  yield_percent,
})

const toPayload = ({ purchase_price, ...rest }) => ({
  ...rest,
  purchase_price_cents: eurosToCents(purchase_price),
})

const IngredientForm = ({
  onSaved,
  ingredientToEdit,
  successMessage,
  setSuccessMessage,
  units,
}) => {
  const [formData, setFormData] = useState(() =>
    ingredientToEdit ? toFormData(ingredientToEdit) : EMPTY_FORM,
  )
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (!successMessage) return
    const id = setTimeout(() => setSuccessMessage(null), 3000)
    return () => clearTimeout(id)
  }, [successMessage, setSuccessMessage])

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSubmitting(true)
    setErrors({})
    setSuccessMessage(null)
    try {
      let result
      if (!ingredientToEdit) {
        result = await createIngredient(toPayload(formData))
        setSuccessMessage(`Added ${result.name}`)
      } else {
        const payload = toPayload(formData)
        result = await updateIngredient(ingredientToEdit.id, payload)
        setSuccessMessage(`Updated ${result.name}`)
      }
      onSaved(result)
      setFormData(EMPTY_FORM)
    } catch (error) {
      setErrors(error.errors ?? { base: [error.message] })
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div>
      <form onSubmit={handleSubmit}>
        <label>
          Ingredient Name:
          <input name="name" value={formData.name} onChange={handleChange} />
        </label>
        {errors.name && <p className="field-error">{errors.name.join(", ")}</p>}
        <label>
          Unit:
          <select
            name="purchase_unit"
            value={formData.purchase_unit}
            onChange={handleChange}
          >
            {Object.keys(units).map((unit) => (
              <option key={unit} value={unit}>
                {unit}
              </option>
            ))}
          </select>
        </label>
        {errors.purchase_unit && (
          <p className="field-error">{errors.purchase_unit.join(", ")}</p>
        )}
        <label>
          Purchase Price:
          <input
            name="purchase_price"
            value={formData.purchase_price}
            onChange={handleChange}
          />
        </label>
        {errors.purchase_price_cents && (
          <p className="field-error">
            {errors.purchase_price_cents.join(", ")}
          </p>
        )}
        <label>
          Quantity:
          <input
            name="purchase_quantity"
            value={formData.purchase_quantity}
            onChange={handleChange}
          />
        </label>
        {errors.purchase_quantity && (
          <p className="field-error">{errors.purchase_quantity.join(", ")}</p>
        )}
        <label>
          Yield Percentage:
          <input
            name="yield_percent"
            value={formData.yield_percent}
            onChange={handleChange}
          />
        </label>
        {errors.yield_percent && (
          <p className="field-error">{errors.yield_percent.join(", ")}</p>
        )}
        <button type="submit" disabled={submitting}>
          {ingredientToEdit ? "Update Ingredient" : "Add Ingredient"}
        </button>
        {errors.base && <p className="field-error">{errors.base.join(", ")}</p>}
        {successMessage && <p role="status">{successMessage}</p>}
      </form>
    </div>
  )
}

export default IngredientForm
