import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const calledOnLabeler = (review: any): void => {
  assert.equal(new review.Labeler("sku").label("a"), "sku-a")
}

const ownPrefix = (review: any): void => {
  const sku = new review.Labeler("sku")
  const box = new review.Labeler("box")
  assert.deepEqual([sku.label("a"), box.label("a")], ["sku-a", "box-a"])
}

const passedAsCallback = (review: any): void => {
  assert.deepEqual(["a", "b"].map(new review.Labeler("sku").label), ["sku-a", "sku-b"])
}

const heldApart = (review: any): void => {
  const { label } = new review.Labeler("box")
  assert.equal(label("c"), "box-c")
}

export const CASES = [
  twin("a label called on its labeler", calledOnLabeler),
  twin("each labeler uses its own prefix", ownPrefix),
  exploit("label passed to map as a callback", passedAsCallback),
  exploit("label taken off its labeler and called alone", heldApart),
]
