const BASE = '/api/v1'

async function request(path, { method = 'GET', body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  })

  // DELETE returns 204 No Content. There's no body, and res.json() would throw
  if (res.status === 204) return null

  const data = await res.json().catch(() => null)

  if (!res.ok) {
    const error = new Error(`Request failed: ${res.status}`)
    error.status = res.status
    error.errors = data?.errors ?? {}
    throw error
  }
  return data
}

/**
 * @typedef {Object} RecipeSummary
 * @property {number} id
 * @property {string} name
 * @property {number} plate_cost_cents
 * @property {string|null} food_cost_percent
 */

/** @returns {Promise<RecipeSummary[]>} */
export const getRecipes = () => request('/recipes')
export const getRecipe = (id) => request(`/recipes/${id}`)
