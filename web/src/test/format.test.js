import { describe, it, expect } from 'vitest'
import { eurosToCents, formatCents, centsToEuros } from '../format'

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

describe('centsToEuros', () => {
  it.each([
    [950, '9.50'],
    [900, '9.00'],
    [50, '0.50'],
    [5, '0.05'],
    [null, ''],
    [0, '0.00'],
  ])('%j -> %j', (input, expected) => {
    expect(centsToEuros(input)).toBe(expected)
  })

  it.each([1999, 29, 1005, 123456])(
    '%i cents round-trip through form',
    (cents) => {
      const formValue = centsToEuros(cents)
      expect(eurosToCents(formValue)).toBe(cents)
    },
  )
})

describe('formatCents', () => {
  it('formats zero instead of hiding it', () => {
    expect(formatCents(0)).toBe('€0.00')
  })
})
