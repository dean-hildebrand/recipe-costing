import { useState, useEffect } from "react"
import { createIngredient } from "../api"
import { eurosToCents } from "../format"

const EMPTY_FORM = {
  name: "",
  purchase_unit: "g",
  purchase_quantity: "",
  purchase_price: "",
  yield_percent: "100",
}

const IngredientForm = ({ onSaved }) => {
  const [formData, setFormData] = useState(EMPTY_FORM)
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)
  const [successMessage, setSuccessMessage] = useState(null)

  useEffect(() => {
    if (!successMessage) return
    const id = setTimeout(() => setSuccessMessage(null), 3000)
    return () => clearTimeout(id)
  }, [successMessage])

  const toPayload = ({ purchase_price, ...rest }) => ({
    ...rest,
    purchase_price_cents: eurosToCents(purchase_price),
  })

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
      const result = await createIngredient(toPayload(formData))
      onSaved(result)
      setFormData(EMPTY_FORM)
      setSuccessMessage(`Added ${result.name}`)
    } catch (error) {
      setErrors(error.errors ?? { base: [error.message] })
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div>
      <form onSubmit={handleSubmit}>
        <label>Ingredient Name:</label>
        <input name="name" value={formData.name} onChange={handleChange} />
        {errors.name && <p>{errors.name.join(", ")}</p>}
        <label>Unit:</label>
        <select
          name="purchase_unit"
          value={formData.purchase_unit}
          onChange={handleChange}
        >
          <option value="g">g</option>
          <option value="kg">kg</option>
          <option value="ml">ml</option>
          <option value="l">l</option>
          <option value="each">each</option>
        </select>
        {errors.purchase_unit && <p>{errors.purchase_unit.join(", ")}</p>}
        <label>Purchase Price:</label>
        <input
          name="purchase_price"
          value={formData.purchase_price}
          onChange={handleChange}
        />
        {errors.purchase_price_cents && (
          <p>{errors.purchase_price_cents.join(", ")}</p>
        )}
        <label>Quantity:</label>
        <input
          name="purchase_quantity"
          value={formData.purchase_quantity}
          onChange={handleChange}
        />
        {errors.purchase_quantity && (
          <p>{errors.purchase_quantity.join(", ")}</p>
        )}
        <label>Yield Percentage:</label>
        <input
          name="yield_percent"
          value={formData.yield_percent}
          onChange={handleChange}
        />
        {errors.yield_percent && <p>{errors.yield_percent.join(", ")}</p>}
        <button type="submit" disabled={submitting}>
          Add Ingredient
        </button>
        {errors.base && <p>{errors.base.join(", ")}</p>}
        {successMessage && <p role="status">{successMessage}</p>}
      </form>
    </div>
  )
}

export default IngredientForm
