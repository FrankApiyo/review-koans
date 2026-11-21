import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const emptyCart = (review: any): void => {
  assert.equal(review.total([]), 0)
}

const singleUnits = (review: any): void => {
  assert.equal(
    review.total([
      { qty: 1, unitCents: 250 },
      { qty: 1, unitCents: 200 },
    ]),
    450,
  )
}

const severalUnits = (review: any): void => {
  assert.equal(
    review.total([
      { qty: 3, unitCents: 250 },
      { qty: 1, unitCents: 200 },
    ]),
    950,
  )
}

export const CASES = [
  twin("an empty cart", emptyCart),
  twin("single units", singleUnits),
  exploit("a line with several units", severalUnits),
]
