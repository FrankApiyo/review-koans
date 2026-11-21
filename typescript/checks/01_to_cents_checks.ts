import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const wholeDollars = (review: any): void => {
  assert.equal(review.toCents(5), 500)
}

const withCents = (review: any): void => {
  assert.equal(review.toCents(1.25), 125)
  assert.equal(review.toCents(1.1), 110)
}

const productJustUnder = (review: any): void => {
  assert.equal(review.toCents(19.99), 1999)
  assert.equal(review.toCents(0.29), 29)
}

const everyCent = (review: any): void => {
  for (let cents = 0; cents <= 10_000; cents++) {
    assert.equal(review.toCents(cents / 100), cents)
  }
}

export const CASES = [
  twin("a whole-dollar price", wholeDollars),
  twin("a price with cents", withCents),
  exploit("a price whose float product lands a hair under its cents", productJustUnder),
  exploit("every price up to a hundred dollars", everyCent),
]
