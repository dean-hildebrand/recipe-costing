import { describe, it, expect, vi, beforeEach } from "vitest"
import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import IngredientsPage from "../../pages/IngredientsPage"
import {
  getIngredients,
  getUnits,
  deleteIngredient,
  updateIngredient,
} from "../../api"

vi.mock("../../api")

const ingredients = [
  {
    id: 1,
    name: "Butter",
    purchase_quantity: 1,
    purchase_unit: "kg",
    purchase_price_cents: 950,
    yield_percent: 100,
  },
  {
    id: 2,
    name: "Flour",
    purchase_quantity: 25,
    purchase_unit: "kg",
    purchase_price_cents: 2000,
    yield_percent: 100,
  },
]

const units = {
  g: "mass",
  kg: "mass",
  ml: "volume",
  l: "volume",
  each: "count",
}

const rowFor = (name) => screen.getByRole("cell", { name }).closest("tr")

const clickDelete = async (user, name) =>
  user.click(within(rowFor(name)).getByRole("button", { name: /delete/i }))

const clickEdit = async (user, name) =>
  user.click(within(rowFor(name)).getByRole("button", { name: /edit/i }))

beforeEach(() => {
  vi.resetAllMocks()
  getIngredients.mockResolvedValue(ingredients)
  getUnits.mockResolvedValue(units)
})

describe("IngredientsPage update ingredient", () => {
  it("shows edit form for row clicked, updates updated price on submit and shows correctly", async () => {
    updateIngredient.mockResolvedValue({
      id: 2,
      name: "Flour",
      purchase_quantity: 25,
      purchase_unit: "kg",
      purchase_price_cents: 2500,
      yield_percent: 100,
    })
    const user = userEvent.setup()
    render(<IngredientsPage />)
    await screen.findByText("Flour")

    await clickEdit(user, "Flour")
    let priceInput = screen.getByLabelText(/purchase price/i)
    await user.clear(priceInput)
    await user.type(priceInput, "25")
    await user.click(screen.getByRole("button", { name: /update ingredient/i }))

    expect(updateIngredient).toHaveBeenCalledWith(
      2,
      expect.objectContaining({ purchase_price_cents: 2500 }),
    )
    // table shows updated price
    expect(await screen.findByText("€25.00")).toBeInTheDocument()
    // old price has been removed/replaced
    expect(screen.queryByText("€20.00")).not.toBeInTheDocument()
    // button back to adding ingredient
    expect(
      screen.getByRole("button", { name: /add ingredient/i }),
    ).toBeInTheDocument()
    expect(screen.getByRole("status")).toHaveTextContent("Updated Flour")
  })
})

describe("IngredientsPage delete errors", () => {
  it("shows the server error directly under the row that failed", async () => {
    deleteIngredient.mockRejectedValue({
      status: 422,
      errors: { base: ["is used in a recipe"] },
    })
    const user = userEvent.setup()
    render(<IngredientsPage />)
    await screen.findByText("Flour")

    await clickDelete(user, "Flour")

    const alert = await screen.findByRole("alert")
    expect(alert).toHaveTextContent("is used in a recipe")
    // the error row sits right after Flour's row, not Butter's
    expect(alert.closest("tr").previousElementSibling).toBe(rowFor("Flour"))
    expect(screen.getAllByRole("alert")).toHaveLength(1)
    // the ingredient stays in the table
    expect(rowFor("Flour")).toBeInTheDocument()
  })

  it("falls back to a status message when the server sends no errors", async () => {
    deleteIngredient.mockRejectedValue({ status: 500, errors: {} })
    const user = userEvent.setup()
    render(<IngredientsPage />)
    await screen.findByText("Butter")

    await clickDelete(user, "Butter")

    expect(await screen.findByRole("alert")).toHaveTextContent(
      "Couldn't delete Butter (500)",
    )
  })

  it("clears the error and removes the row when a retry succeeds", async () => {
    deleteIngredient
      .mockRejectedValueOnce({ status: 500, errors: {} })
      .mockResolvedValueOnce(null)
    const user = userEvent.setup()
    render(<IngredientsPage />)
    await screen.findByText("Flour")

    await clickDelete(user, "Flour")
    await screen.findByRole("alert")

    await clickDelete(user, "Flour")

    expect(screen.queryByText("Flour")).not.toBeInTheDocument()
    expect(screen.getByText("Butter")).toBeInTheDocument()
    expect(screen.queryByRole("alert")).not.toBeInTheDocument()
  })
})
