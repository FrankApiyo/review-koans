import assert from "node:assert/strict"
import { twin } from "#koans"

const addsAnItem = (review: any): void => {
  assert.deepEqual(review.add({}, "PEAR-7", 2), { "PEAR-7": 2 })
}

export const CASES = [twin("adding an item", addsAnItem)]
