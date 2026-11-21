import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const wellFormed = (review: any): void => {
  assert.equal(review.isOrder({ items: [{ sku: "a", qty: 2 }, { sku: "b", qty: 0 }] }), true)
}

const emptyItems = (review: any): void => {
  assert.equal(review.isOrder({ items: [] }), true)
}

const notAnOrderShape = (review: any): void => {
  for (const x of [1, "order", {}, { items: {} }, [], undefined]) assert.equal(review.isOrder(x), false)
}

const badItems = (review: any): void => {
  assert.equal(review.isOrder({ items: [{ sku: "a", qty: "2" }] }), false)
  assert.equal(review.isOrder({ items: [{ qty: 2 }] }), false)
  assert.equal(review.isOrder({ items: [7] }), false)
}

const nullValue = (review: any): void => {
  assert.equal(review.isOrder(null), false)
}

const nullItem = (review: any): void => {
  assert.equal(review.isOrder({ items: [{ sku: "a", qty: 1 }, null] }), false)
}

const fractionalQuantity = (review: any): void => {
  assert.equal(review.isOrder({ items: [{ sku: "a", qty: 2.5 }] }), false)
}

export const CASES = [
  twin("a well-formed order is an order", wellFormed),
  twin("an order with an empty list of items is an order", emptyItems),
  twin("a value without a list of items is not an order", notAnOrderShape),
  twin("an item with a text quantity, no sku, or no fields is refused", badItems),
  exploit("null is not an order", nullValue),
  exploit("a list holding a null item is not an order", nullItem),
  exploit("a fractional quantity is not an order", fractionalQuantity),
]
