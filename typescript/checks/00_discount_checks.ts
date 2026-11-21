import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const noDiscount = (review: any): void => {
  assert.equal(review.discounted(1000, 0), 1000)
}

const ordinaryDiscount = (review: any): void => {
  assert.equal(review.discounted(1000, 10), 900)
  assert.equal(review.discounted(100, 29), 71)
}

const unevenDiscount = (review: any): void => {
  assert.equal(review.discounted(999, 10), 900)
}

export const CASES = [
  twin("a price with no discount", noDiscount),
  exploit("an ordinary discount", ordinaryDiscount),
  exploit("a discount that does not divide evenly", unevenDiscount),
]
