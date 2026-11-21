import assert from "node:assert/strict"
import { twin } from "#koans"

const counts = (review: any): void => {
  assert.equal(review.count("PEAR-7"), 0)
}

export const CASES = [twin("counting stock", counts)]
