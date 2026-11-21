import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const emptyAndMissing = (review: any): void => {
  assert.equal(review.isBlank(""), true)
  assert.equal(review.isBlank(null), true)
  assert.equal(review.isBlank(undefined), true)
}

const zeroAsText = (review: any): void => {
  assert.equal(review.isBlank("0"), false)
}

const numberZero = (review: any): void => {
  assert.equal(review.isBlank(0), false)
}

const falseValue = (review: any): void => {
  assert.equal(review.isBlank(false), false)
}

const emptyList = (review: any): void => {
  assert.equal(review.isBlank([]), false)
}

const otherEmptyValues = (review: any): void => {
  for (const value of [-0, NaN, 0n, {}, " ", "false"]) {
    assert.equal(review.isBlank(value), false)
  }
}

export const CASES = [
  twin("the empty string and missing values are blank", emptyAndMissing),
  twin("text holding a zero is not blank", zeroAsText),
  exploit("the number zero is not blank", numberZero),
  exploit("false is not blank", falseValue),
  exploit("an empty list is not blank", emptyList),
  exploit("no other falsy or empty-looking value is blank", otherEmptyValues),
]
