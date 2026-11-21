import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const PRICES = [29, 50, 100, 999]
const PERCENTS = Array.from({ length: 101 }, (_, percent) => percent)

const noDiscount = (review: any): void => {
  assert.equal(review.discounted(1000, 0), 1000)
}

const ordinaryDiscount = (review: any): void => {
  assert.equal(review.discounted(1000, 10), 900)
}

const unevenDiscount = (review: any): void => {
  assert.equal(review.discounted(999, 10), 900)
}

const everyPercent = (review: any): void => {
  for (const price of PRICES) {
    for (const percent of PERCENTS) {
      const result = review.discounted(price, percent)
      assert.ok(Number.isInteger(result))
      const discount = price - result
      assert.ok(discount * 100 <= price * percent && price * percent < (discount + 1) * 100)
    }
  }
}

export const CASES = [
  twin("a price with no discount", noDiscount),
  exploit("an ordinary discount", ordinaryDiscount),
  exploit("a discount that does not divide evenly", unevenDiscount),
  exploit("every whole percent off a price", everyPercent),
]
