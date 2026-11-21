import assert from "node:assert/strict"
import { twin } from "#koans"

const addsOne = (review: any): void => {
  assert.deepEqual(review.add("PEAR-7"), ["PEAR-7"])
}

export const CASES = [twin("adding an item", addsOne), twin("adding an item again", addsOne)]
