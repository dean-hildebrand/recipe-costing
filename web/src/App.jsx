import { useState } from "react"
import RecipesPage from "./pages/RecipesPage"
import IngredientsPage from "./pages/IngredientsPage"

function App() {
  const [page, setPage] = useState("recipes")

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
          onClick={() => setPage("ingredients")}
        >
          Ingredients
        </button>
      </nav>
      {page === "recipes" ? <RecipesPage /> : <IngredientsPage />}
    </>
  )
}

export default App
