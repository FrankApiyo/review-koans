import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const itemAddedLast = (review: any): void => {
  const cart = { owner: "ann", items: ["a"] }
  assert.deepEqual(review.addItem(cart, "b").items, ["a", "b"])
}

const otherFieldsKept = (review: any): void => {
  const cart = { owner: "ann", items: ["a"] }
  assert.equal(review.addItem(cart, "b").owner, "ann")
}

const callerCartUnchanged = (review: any): void => {
  const items = ["a"]
  const cart = { owner: "ann", items }
  review.addItem(cart, "b")
  assert.deepEqual(cart, { owner: "ann", items: ["a"] })
  assert.deepEqual(items, ["a"])
}

const twoCartsFromOne = (review: any): void => {
  const cart = { owner: "ann", items: ["a"] }
  const withB = review.addItem(cart, "b")
  const withC = review.addItem(cart, "c")
  assert.deepEqual(withB.items, ["a", "b"])
  assert.deepEqual(withC.items, ["a", "c"])
}

export const CASES = [
  twin("the returned cart holds the new item after the old ones", itemAddedLast),
  twin("the returned cart keeps the cart's other fields", otherFieldsKept),
  exploit("the caller's cart and its items are left as they were", callerCartUnchanged),
  exploit("two carts made from one cart each hold only their own item", twoCartsFromOne),
]
