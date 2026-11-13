import IngredientTableRow from "./IngredientTableRow"

const IngredientsTable = ({ ingredients }) => {
  return (
    <>
      <div>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Quantity</th>
              <th>Unit</th>
              <th>Price</th>
              <th>Yield Percent</th>
            </tr>
          </thead>
          <tbody>
            {ingredients.map((ingredient) => (
              <IngredientTableRow key={ingredient.id} ingredient={ingredient} />
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}

export default IngredientsTable
