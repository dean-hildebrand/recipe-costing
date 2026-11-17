const IngredientActions = ({ ingredient, handleDelete, handleEdit }) => {
  return (
    <div>
      <button onClick={() => handleDelete(ingredient)}>Delete</button>
      <button onClick={() => handleEdit(ingredient)}>Edit</button>
    </div>
  )
}

export default IngredientActions
