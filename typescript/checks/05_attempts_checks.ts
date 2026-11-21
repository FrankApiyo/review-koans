import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const notGiven = (review: any): void => {
  assert.equal(review.attempts({}), 4)
  assert.equal(review.attempts({ retries: undefined }), 4)
}

const someRetries = (review: any): void => {
  assert.equal(review.attempts({ retries: 2 }), 3)
}

const zeroRetries = (review: any): void => {
  assert.equal(review.attempts({ retries: 0 }), 1)
}

export const CASES = [
  twin("with retries not given, three retries follow the first try", notGiven),
  twin("the retries given follow the first try", someRetries),
  exploit("zero retries means only the first try", zeroRetries),
]
