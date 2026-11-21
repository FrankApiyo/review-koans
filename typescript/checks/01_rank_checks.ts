import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const noScores = (review: any): void => {
  assert.deepEqual(review.rank([]), [])
}

const singleDigits = (review: any): void => {
  assert.deepEqual(review.rank([3, 1, 2]), [1, 2, 3])
}

const mixedDigits = (review: any): void => {
  assert.deepEqual(review.rank([10, 9, 1, 100, -3]), [-3, 1, 9, 10, 100])
}

const inputUnchanged = (review: any): void => {
  const scores = [10, 9, 1, 100, -3]
  review.rank(scores)
  assert.deepEqual(scores, [10, 9, 1, 100, -3])
}

export const CASES = [
  twin("no scores", noScores),
  exploit("scores come back lowest first", singleDigits),
  exploit("scores are ordered by numeric value, not as text", mixedDigits),
  exploit("the caller's list is left as it was", inputUnchanged),
]
