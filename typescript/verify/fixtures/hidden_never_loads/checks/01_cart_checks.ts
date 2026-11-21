import assert from "node:assert/strict"
import { exploit } from "#koans"

const unknownItem = (review: any): void => {
  assert.equal(review.price({}, "GHOST-1"), undefined)
}

export const CASES = [exploit("an unknown item", unknownItem)]
