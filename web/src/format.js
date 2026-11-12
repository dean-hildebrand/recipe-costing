const eur = new Intl.NumberFormat('en-IE', {
  style: 'currency',
  currency: 'EUR',
})
export const formatCents = (cents) => {
  if (!cents) return null

  return eur.format(cents / 100)
}
