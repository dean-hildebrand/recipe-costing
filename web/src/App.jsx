import { useState } from "react"
import RecipesPage from "./pages/RecipesPage"
import IngredientsPage from "./pages/IngredientsPage"
import RecipeEditor from "./components/recipes/RecipeEditor"

function App() {
  const [page, setPage] = useState("recipes")
  const [recipeId, setRecipeId] = useState(null)

  const onBack = () => {
    setRecipeId(null)
  }

  return (
    <>
      <nav>
        <button
          className={page === "recipes" ? "active" : ""}
          onClick={() => setPage("recipes")}
        >
          Recipes
        </button>
        <button
          className={page === "ingredients" ? "active" : ""}
          onClick={() => {
            setPage("ingredients")
            setRecipeId(null)
          }}
        >
          Ingredients
        </button>
      </nav>
      {page === "recipes" ? (
        recipeId ? (
          <RecipeEditor
            recipeId={recipeId}
            setRecipeId={setRecipeId}
            onBack={onBack}
          />
        ) : (
          <RecipesPage onSelectRecipe={setRecipeId} />
        )
      ) : (
        <IngredientsPage />
      )}
    </>
  )
}

export default App
