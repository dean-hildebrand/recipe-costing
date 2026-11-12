// import { formatCents } from "../format"

const IngredientTableRow = ({ ingredient }) => {
  return (
    <tr>
      <td>{ingredient.name}</td>
      <td>{ingredient.purchase_quantity}</td>
      <td>{ingredient.purchase_unit}</td>
      {/* <td>{formatCents(ingredient.purchase_price_cents)}</td> */}
    </tr>
  )
}

export default IngredientTableRow
