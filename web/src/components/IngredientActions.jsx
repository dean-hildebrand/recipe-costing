const IngredientActions = ({ ingredient, handleDelete }) => {
  return (
    <div>
      <button onClick={() => handleDelete(ingredient)}>Delete</button>
      <button onClick={() => console.log("Editing ingredient", ingredient.id)}>
        Edit
      </button>
    </div>
  )
}

export default IngredientActions
