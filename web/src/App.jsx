import { useState } from "react"
import RecipesPage from "./pages/RecipesPage"
import IngredientsPage from "./pages/IngredientsPage"

function App() {
  const [page, setPage] = useState("recipes")

  return (
    <>
      <nav>
        <button onClick={() => setPage("recipes")}>Recipes</button>
        <button onClick={() => setPage("ingredients")}>Ingredients</button>
      </nav>
      {page === "recipes" ? <RecipesPage /> : <IngredientsPage />}
    </>
  )
}

export default App
