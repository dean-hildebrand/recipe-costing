import IngredientTableRow from "./IngredientTableRow"

const IngredientsTable = ({
  ingredients,
  handleDelete,
  deleteError,
  handleEdit,
}) => {
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
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {ingredients.map((ingredient) => (
              <IngredientTableRow
                key={ingredient.id}
                ingredient={ingredient}
                handleDelete={handleDelete}
                handleEdit={handleEdit}
                deleteError={
                  deleteError?.id === ingredient.id ? deleteError.message : null
                }
              />
            ))}
          </tbody>
        </table>
      </div>
    </>
  )
}

export default IngredientsTable
