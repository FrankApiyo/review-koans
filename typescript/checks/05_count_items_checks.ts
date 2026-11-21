import assert from "node:assert/strict"
import { exploit, throws, twin } from "#koans"

const body = (items: unknown): string => JSON.stringify({ items })

const wholeQuantities = (review: any): void => {
  assert.equal(review.countItems(body([{ sku: "a", qty: 1 }, { sku: "b", qty: 2 }])), 3)
  assert.equal(review.countItems(body([{ sku: "a", qty: 0 }, { sku: "b", qty: 3 }])), 3)
}

const noItems = (review: any): void => {
  assert.equal(review.countItems(body([])), 0)
}

const noList = (review: any): void => {
  throws(() => review.countItems("{}"))
  throws(() => review.countItems(JSON.stringify({ items: {} })))
  throws(() => review.countItems("null"))
}

const textQuantity = (review: any): void => {
  throws(() => review.countItems(body([{ sku: "a", qty: 1 }, { sku: "b", qty: "2" }])))
}

const fractionalQuantity = (review: any): void => {
  throws(() => review.countItems(body([{ sku: "a", qty: 2.5 }])))
}

const negativeQuantity = (review: any): void => {
  throws(() => review.countItems(body([{ sku: "a", qty: 4 }, { sku: "b", qty: -1 }])))
}

const endlessQuantity = (review: any): void => {
  throws(() => review.countItems('{"items":[{"sku":"a","qty":1e999}]}'))
}

export const CASES = [
  twin("whole-number quantities are summed, zero included", wholeQuantities),
  twin("an order with an empty list of items counts zero", noItems),
  twin("a body without a list of items throws", noList),
  exploit("a quantity sent as text throws", textQuantity),
  exploit("a fractional quantity throws", fractionalQuantity),
  exploit("a negative quantity throws", negativeQuantity),
  exploit("a quantity too large to be a whole number throws", endlessQuantity),
]
