import { describe, it, expect, vi, beforeEach } from "vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import IngredientForm from "../../components/IngredientForm"
import { createIngredient } from "../../api"

vi.mock("../../api")

beforeEach(() => vi.resetAllMocks())

describe("IngredientForm", () => {
  it("sends the price in cents", async () => {
    createIngredient.mockResolvedValue({ id: 1, name: "Butter" })
    const user = userEvent.setup()
    render(<IngredientForm onSaved={vi.fn()} />)

    await user.type(screen.getByLabelText(/name/i), "Butter")
    await user.type(screen.getByLabelText(/price/i), "9.50")
    await user.click(screen.getByRole("button", { name: /add/i }))

    expect(createIngredient).toHaveBeenCalledWith(
      expect.objectContaining({ name: "Butter", purchase_price_cents: 950 }),
    )
  })

  it("shows server errors next to the field", async () => {
    createIngredient.mockRejectedValue({
      errors: { name: ["has already been taken"] },
    })
    const user = userEvent.setup()
    render(<IngredientForm onSaved={vi.fn()} />)

    await user.click(screen.getByRole("button", { name: /add/i }))

    expect(
      await screen.findByText("has already been taken"),
    ).toBeInTheDocument()
  })
})
