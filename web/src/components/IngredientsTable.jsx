import IngredientTableRow from "./IngredientTableRow"
const IngredientsTable = ({ ingredients }) => {
  return (
    <table>
      <thead>
        <tr>
          <th>Name</th>
          <th>Quantity</th>
          <th>Unit</th>
          <th>Price</th>
        </tr>
      </thead>
      <tbody>
        {ingredients.map((ingredient) => (
          <IngredientTableRow key={ingredient.id} ingredient={ingredient} />
        ))}
      </tbody>
    </table>
  )
}

export default IngredientsTable
