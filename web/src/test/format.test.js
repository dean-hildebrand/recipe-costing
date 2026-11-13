import { describe, it, expect } from 'vitest'
import { eurosToCents, formatCents } from '../format'

describe('eurosToCents', () => {
  it.each([
    ['9.50', 950],
    ['9.5', 950],
    ['9.', 900],
    ['.5', 50],
    ['1.005', null], // Math.round(parseFloat('1.005') * 100) would give 100
    ['', null],
    ['.', null],
    ['9,50', null],
    ['abc', null],
  ])('%j -> %j', (input, expected) => {
    expect(eurosToCents(input)).toBe(expected)
  })
})

describe('formatCents', () => {
  it('formats zero instead of hiding it', () => {
    expect(formatCents(0)).toBe('€0.00')
  })
})
