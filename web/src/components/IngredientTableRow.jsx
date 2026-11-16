import { formatCents } from "../format"
import IngredientActions from "./IngredientActions"

const IngredientTableRow = ({ ingredient, handleDelete, deleteError }) => {
  return (
    <>
      <tr>
        <td>{ingredient.name}</td>
        <td>{ingredient.purchase_quantity}</td>
        <td>{ingredient.purchase_unit}</td>
        <td>{formatCents(ingredient.purchase_price_cents)}</td>
        <td>{ingredient.yield_percent}%</td>
        <td>
          <IngredientActions
            ingredient={ingredient}
            handleDelete={handleDelete}
          />
        </td>
      </tr>
      {deleteError && (
        <tr>
          <td colSpan={6} role="alert">
            {deleteError}
          </td>
        </tr>
      )}
    </>
  )
}

export default IngredientTableRow
