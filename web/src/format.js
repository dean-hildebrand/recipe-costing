const eur = new Intl.NumberFormat('en-IE', {
  style: 'currency',
  currency: 'EUR',
})
export const formatCents = (cents) => {
  if (cents == null) return null

  return eur.format(cents / 100)
}

export const centsToEuros = (cents) => {
  if (cents == null) return ''
  const convertedCents = cents / 100
  return convertedCents.toFixed(2)
}

export const eurosToCents = (price) => {
  if (typeof price !== 'string') return null

  const trimmed = price.trim()
  const match = trimmed.match(/^(?=.*\d)(\d*)(?:\.(\d{0,2}))?$/)
  if (match == null) return null

  const [, euros, cents = ''] = match
  const paddedCents = cents.padEnd(2, '0')

  return Number(euros) * 100 + Number(paddedCents)
}
