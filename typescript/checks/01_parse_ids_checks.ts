import assert from "node:assert/strict"
import { exploit, twin } from "#koans"

const oneId = (review: any): void => {
  assert.deepEqual(review.parseIds("7"), [7])
}

const severalIds = (review: any): void => {
  assert.deepEqual(review.parseIds("10,11,12"), [10, 11, 12])
}

const leadingZeros = (review: any): void => {
  assert.deepEqual(review.parseIds("08,09"), [8, 9])
}

export const CASES = [
  twin("a single id", oneId),
  exploit("every id after the first is read in base ten", severalIds),
  exploit("ids with a leading zero are read in base ten", leadingZeros),
]
