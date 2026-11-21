import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const highestFirst = (review: any): void => {
  assert.deepEqual(review.topThree([5, 90, 40, 70, 100]), [100, 90, 70])
}

const fewerThanThree = (review: any): void => {
  assert.deepEqual(review.topThree([5, 40]), [40, 5])
}

const callerListUnchanged = (review: any): void => {
  const scores = [5, 90, 40, 70]
  review.topThree(scores)
  assert.deepEqual(scores, [5, 90, 40, 70])
}

export const CASES = [
  twin("the three highest scores come back highest first", highestFirst),
  twin("a list of fewer than three scores comes back whole, highest first", fewerThanThree),
  exploit("the caller's list keeps its order", callerListUnchanged),
]
