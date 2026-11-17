const IngredientActions = ({ ingredient, handleDelete, handleEdit }) => {
  return (
    <div className="actions">
      <button className="danger" onClick={() => handleDelete(ingredient)}>
        Delete
      </button>
      <button className="secondary" onClick={() => handleEdit(ingredient)}>
        Edit
      </button>
    </div>
  )
}

export default IngredientActions
