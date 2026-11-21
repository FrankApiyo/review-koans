import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const addsAnItem = (review: any): void => {
  assert.deepEqual(review.add({}, "PEAR-7", 2), { "PEAR-7": 2 })
}

const emptyAdd = (review: any): void => {
  assert.deepEqual(review.add({}, "ZX-99", 0), {})
}

export const CASES = [twin("adding an item", addsAnItem), exploit("an empty add", emptyAdd)]
